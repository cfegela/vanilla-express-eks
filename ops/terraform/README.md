# Infrastructure as Code with Terraform

This directory contains the Terraform configuration to provision a production-ready AWS EKS cluster running on Fargate, including networking, security, and load balancing.

## Architecture

The infrastructure includes:
- **VPC**: A dedicated VPC with public and private subnets across two availability zones.
- **EKS Cluster**: An Amazon EKS cluster configured to use AWS Fargate for serverless container execution.
- **Fargate Profiles**:
  - `default`: For application workloads in the default namespace.
  - `kube-system`: For core Kubernetes components.
  - `aws-load-balancer-controller`: Specifically for the ALB controller.
- **AWS Load Balancer Controller**: Installed via Helm to manage Application Load Balancers (ALB) for Ingress.
- **External DNS** (optional): Automatically manages Route53 DNS records for Ingress resources.
- **Nginx Demo**: A sample "Hello World" deployment to verify the stack.

## External Dependencies

This Terraform configuration **references but does not create** the following resources. These must exist before running `terraform apply`:

| Resource | Variable | Description |
|----------|----------|-------------|
| **ACM Certificate** | `acm_certificate_arn` | SSL/TLS certificate for HTTPS on the ALB |
| **Route53 Hosted Zone** | `hosted_zone_id`, `hosted_zone_name` | DNS zone for the domain |
| **S3 State Bucket** | Configured in `state.tf` | Backend storage for Terraform state |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- An existing ACM certificate for your domain
- A Route53 hosted zone for your domain

## Getting Started

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Configure Variables**:
   Create a `terraform.tfvars` file based on `terraform.tfvars.example`:
   ```hcl
   aws_region          = "us-east-1"
   cluster_name        = "my-eks-cluster"
   kubernetes_version  = "1.31"
   vpc_cidr            = "10.0.0.0/16"
   domain_name         = "app.example.com"
   acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
   hosted_zone_name    = "example.com"
   hosted_zone_id      = "Z1234567890ABC"
   enable_external_dns = true
   ```

3. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

4. **Update Kubeconfig**:
   After the apply completes, use the output command to configure `kubectl`:
   ```bash
   aws eks update-kubeconfig --name <cluster_name> --region <region>
   ```

## Key Components

### AWS Load Balancer Controller
The configuration includes the necessary IAM roles and policies (IRSA) to allow the Load Balancer Controller to manage ALBs. It is deployed into the `kube-system` namespace.

### External DNS
When `enable_external_dns = true`, the external-dns controller is deployed to automatically create and manage Route53 DNS records based on Ingress annotations. This eliminates the need to manually create DNS records.

### CoreDNS Patch
Since this is a Fargate-only cluster, a `null_resource` is used to patch the `coredns` deployment to remove the default EC2 compute type annotation, allowing it to run on Fargate.

### SSL/TLS
Ingress is configured to use the provided ACM certificate and enforces SSL redirection by default.

### Remote State
Terraform state is stored in an S3 backend with native state locking enabled. The backend configuration is in `state.tf`.

## Cleanup

To destroy the provisioned infrastructure:
```bash
terraform destroy
```

### Resources NOT Destroyed by `terraform destroy`

The following resources will **persist** after running `terraform destroy`:

#### Dynamically Created Resources
| Resource | Created By | Reason |
|----------|------------|--------|
| **Application Load Balancers** | AWS LB Controller | Created dynamically based on Kubernetes Ingress resources |
| **Target Groups** | AWS LB Controller | Created dynamically by the ALB Controller |
| **Route53 DNS Records** | external-dns | Created dynamically based on Ingress annotations (if enabled) |

### Manual Cleanup Steps

After running `terraform destroy`, verify and clean up these resources if needed:

1. **ALBs and Target Groups**: Check the EC2 console for any orphaned load balancers or target groups created by the ALB Controller.
2. **Route53 Records**: If using external-dns, verify DNS records were cleaned up in your hosted zone.
