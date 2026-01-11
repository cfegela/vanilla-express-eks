# Nginx Hello World Deployment
resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx-hello-world"
    namespace = "default"
    labels = {
      app = "nginx-hello-world"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx-hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-hello-world"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/usr/share/nginx/html"
          }

          resources {
            limits = {
              cpu    = "256m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "128m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map_v1.nginx_html.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_fargate_profile.default,
    null_resource.coredns_patch
  ]
}

# ConfigMap for custom HTML
resource "kubernetes_config_map_v1" "nginx_html" {
  metadata {
    name      = "nginx-html"
    namespace = "default"
  }

  data = {
    "index.html" = <<-EOF
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Hello World - EKS Fargate</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  min-height: 100vh;
                  margin: 0;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  color: white;
              }
              .container {
                  text-align: center;
                  padding: 2rem;
                  background: rgba(255,255,255,0.1);
                  border-radius: 16px;
                  backdrop-filter: blur(10px);
              }
              h1 {
                  font-size: 3rem;
                  margin-bottom: 1rem;
              }
              p {
                  font-size: 1.2rem;
                  opacity: 0.9;
              }
              .stack-info {
                  margin-top: 2rem;
                  padding: 1rem;
                  background: rgba(0,0,0,0.2);
                  border-radius: 8px;
                  font-family: monospace;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>Hello World!</h1>
              <p>Welcome to your EKS Fargate cluster</p>
              <div class="stack-info">
                  <p>AWS EKS + Fargate + ALB + SSL</p>
              </div>
          </div>
      </body>
      </html>
    EOF
  }

  depends_on = [aws_eks_cluster.main]
}

# Nginx Service
resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx-hello-world"
    namespace = "default"
  }

  spec {
    selector = {
      app = "nginx-hello-world"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.nginx]
}

# Ingress with ALB
resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name      = "nginx-hello-world"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.main.arn
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.domain_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.nginx.metadata[0].name
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
    kubernetes_service_v1.nginx
  ]
}
