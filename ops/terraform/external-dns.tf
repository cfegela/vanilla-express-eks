# External DNS - Automatically manages Route53 DNS records for Kubernetes resources

# IAM Policy for External DNS
resource "aws_iam_policy" "external_dns" {
  count       = var.enable_external_dns ? 1 : 0
  name        = "${var.cluster_name}-ExternalDNSPolicy"
  description = "IAM policy for External DNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${local.hosted_zone_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# IAM Role for External DNS
resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0
  name  = "${var.cluster_name}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  policy_arn = aws_iam_policy.external_dns[0].arn
  role       = aws_iam_role.external_dns[0].name
}

# Kubernetes Service Account for External DNS
resource "kubernetes_service_account_v1" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
    }
  }

  depends_on = [aws_eks_cluster.main]
}

# Fargate Profile for External DNS
resource "aws_eks_fargate_profile" "external_dns" {
  count                  = var.enable_external_dns ? 1 : 0
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "external-dns"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "external-dns"
    }
  }
}

# External DNS Helm Chart
resource "helm_release" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.14.3"

  set = [
    {
      name  = "provider.name"
      value = "aws"
    },
    {
      name  = "env[0].name"
      value = "AWS_DEFAULT_REGION"
    },
    {
      name  = "env[0].value"
      value = var.aws_region
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.external_dns[0].metadata[0].name
    },
    {
      name  = "domainFilters[0]"
      value = var.hosted_zone_name
    },
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "registry"
      value = "txt"
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    },
    {
      name  = "sources[0]"
      value = "ingress"
    }
  ]

  depends_on = [
    aws_eks_fargate_profile.external_dns,
    kubernetes_service_account_v1.external_dns,
    null_resource.coredns_patch
  ]
}
