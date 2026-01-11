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
  description = "Domain name for the SSL certificate and ingress"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name for DNS validation"
  type        = string
  default     = ""
}

variable "create_dns_records" {
  description = "Whether to create Route53 DNS records for certificate validation"
  type        = bool
  default     = false
}
