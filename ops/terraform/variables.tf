variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-fargate-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Domain name for the ingress"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name for external-dns domain filter"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for external-dns"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "enable_external_dns" {
  description = "Enable external-dns to automatically manage Route53 DNS records for Ingress resources"
  type        = bool
  default     = false
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for static frontend hosting"
  type        = bool
  default     = false
}

variable "frontend_domain_name" {
  description = "Domain name for the CloudFront frontend (e.g., cfeg-ui.cwf.oddball.io)"
  type        = string
  default     = ""
}

variable "frontend_api_url" {
  description = "API URL to inject into frontend app.js (must be HTTPS)"
  type        = string
  default     = ""
}
