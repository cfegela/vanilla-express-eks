# =============================================================================
# Backend API Deployment
# =============================================================================

# ECR Repository for Backend Docker Image
resource "aws_ecr_repository" "backend" {
  count                = var.enable_backend ? 1 : 0
  name                 = "${var.cluster_name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.cluster_name}-backend"
  }
}

# ECR Lifecycle Policy - Keep last 10 images
resource "aws_ecr_lifecycle_policy" "backend" {
  count      = var.enable_backend ? 1 : 0
  repository = aws_ecr_repository.backend[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# Docker Image Build and Push
# =============================================================================

# Build and push Docker image to ECR
resource "null_resource" "backend_docker_build" {
  count = var.enable_backend ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../../backend/Dockerfile")
    package_hash    = filemd5("${path.module}/../../backend/package.json")
    server_hash     = filemd5("${path.module}/../../backend/server.js")
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Get ECR login (use podman which is available on this system)
      aws ecr get-login-password --region ${var.aws_region} | \
        podman login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

      # Build the image for linux/amd64 (Fargate architecture)
      podman build --platform linux/amd64 -t ${aws_ecr_repository.backend[0].repository_url}:latest \
        ${path.module}/../../backend

      # Push to ECR
      podman push ${aws_ecr_repository.backend[0].repository_url}:latest

      # Tag with git commit SHA if available
      GIT_SHA=$(cd ${path.module}/../../ && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
      podman tag ${aws_ecr_repository.backend[0].repository_url}:latest \
        ${aws_ecr_repository.backend[0].repository_url}:$GIT_SHA
      podman push ${aws_ecr_repository.backend[0].repository_url}:$GIT_SHA
    EOT
  }

  depends_on = [aws_ecr_repository.backend]
}

# =============================================================================
# Kubernetes Secret for JWT
# =============================================================================

# JWT Secrets
resource "kubernetes_secret_v1" "backend_jwt" {
  count = var.enable_backend ? 1 : 0

  metadata {
    name      = "backend-jwt-secrets"
    namespace = "default"
  }

  data = {
    JWT_ACCESS_SECRET  = var.backend_jwt_access_secret
    JWT_REFRESH_SECRET = var.backend_jwt_refresh_secret
  }

  type = "Opaque"

  depends_on = [aws_eks_cluster.main]
}

# =============================================================================
# Kubernetes Deployment
# =============================================================================

resource "kubernetes_deployment_v1" "backend" {
  count = var.enable_backend ? 1 : 0

  metadata {
    name      = "backend-api"
    namespace = "default"
    labels = {
      app = "backend-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "backend-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-api"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "${aws_ecr_repository.backend[0].repository_url}:latest"

          port {
            container_port = 3000
          }

          # Environment variables from secret
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.backend_jwt[0].metadata[0].name
            }
          }

          # Additional environment variables
          env {
            name  = "PORT"
            value = "3000"
          }

          env {
            name  = "JWT_ACCESS_EXPIRY"
            value = "15m"
          }

          env {
            name  = "JWT_REFRESH_EXPIRY"
            value = "7d"
          }

          # Mount emptyDir volume for data (ephemeral)
          volume_mount {
            name       = "backend-data"
            mount_path = "/app/data"
          }

          resources {
            limits = {
              cpu    = "512m"
              memory = "1024Mi"
            }
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        # EFS volume (direct mount - supported on Fargate)
        volume {
          name = "backend-data"
          nfs {
            server = aws_efs_file_system.backend[0].dns_name
            path   = "/"
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_fargate_profile.default,
    null_resource.coredns_patch,
    null_resource.backend_docker_build,
    aws_efs_mount_target.backend
  ]
}

# =============================================================================
# Kubernetes Service
# =============================================================================

resource "kubernetes_service_v1" "backend" {
  count = var.enable_backend ? 1 : 0

  metadata {
    name      = "backend-api"
    namespace = "default"
  }

  spec {
    selector = {
      app = "backend-api"
    }

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.backend]
}

# =============================================================================
# Kubernetes Ingress (ALB)
# =============================================================================

resource "kubernetes_ingress_v1" "backend" {
  count = var.enable_backend ? 1 : 0

  metadata {
    name      = "backend-api"
    namespace = "default"
    annotations = merge(
      {
        "kubernetes.io/ingress.class"                            = "alb"
        "alb.ingress.kubernetes.io/scheme"                       = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"                  = "ip"
        "alb.ingress.kubernetes.io/listen-ports"                 = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"                 = "443"
        "alb.ingress.kubernetes.io/certificate-arn"              = local.certificate_arn
        "alb.ingress.kubernetes.io/healthcheck-path"             = "/health"
        "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "30"
        "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
        "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
        "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "3"
      },
      var.enable_external_dns ? {
        "external-dns.alpha.kubernetes.io/hostname" = var.backend_domain_name
      } : {}
    )
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.backend_domain_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.backend[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_service_v1.backend
  ]
}

# =============================================================================
# Admin User Seeding (One-time initialization)
# =============================================================================

resource "null_resource" "backend_seed_admin" {
  count = var.enable_backend && var.backend_admin_password != "" ? 1 : 0

  triggers = {
    # Run when deployment changes or admin credentials change
    deployment_id = kubernetes_deployment_v1.backend[0].metadata[0].uid
    username      = var.backend_admin_username
    password_hash = sha256(var.backend_admin_password)
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Update kubeconfig
      aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region} --kubeconfig /tmp/kubeconfig-${var.cluster_name}
      export KUBECONFIG=/tmp/kubeconfig-${var.cluster_name}

      echo "Waiting for backend pods to be ready..."
      kubectl wait --for=condition=ready pod -l app=backend-api --timeout=300s || echo "Warning: Timeout waiting for pods"

      # Get the first ready pod
      POD_NAME=$(kubectl get pods -l app=backend-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

      if [ -z "$POD_NAME" ]; then
        echo "Error: No backend pods found"
        exit 1
      fi

      echo "Found pod: $POD_NAME"

      # Check if admin user already exists
      ADMIN_EXISTS=$(kubectl exec $POD_NAME -- cat /app/data/auth-users.json 2>/dev/null | grep -c '"username":"${var.backend_admin_username}"' || echo "0")

      if [ "$ADMIN_EXISTS" -eq "0" ]; then
        echo "Creating admin user..."
        kubectl exec $POD_NAME -- node /app/scripts/seed-admin.js "${var.backend_admin_username}" "${var.backend_admin_password}"
        echo "Admin user created successfully"
      else
        echo "Admin user already exists, skipping..."
      fi

      # Cleanup
      rm -f /tmp/kubeconfig-${var.cluster_name}
    EOT
  }

  depends_on = [
    kubernetes_deployment_v1.backend
  ]
}
