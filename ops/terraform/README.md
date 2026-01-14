# Infrastructure as Code with Terraform

This directory contains the Terraform configuration to provision a production-ready AWS EKS cluster running on Fargate, including networking, security, and load balancing.

## Architecture

The infrastructure includes:

### Backend Infrastructure (EKS)
- **VPC**: A dedicated VPC with public and private subnets across two availability zones.
- **EKS Cluster**: An Amazon EKS cluster configured to use AWS Fargate for serverless container execution.
- **Fargate Profiles**:
  - `default`: For application workloads in the default namespace.
  - `kube-system`: For core Kubernetes components.
  - `aws-load-balancer-controller`: Specifically for the ALB controller.
- **AWS Load Balancer Controller**: Installed via Helm to manage Application Load Balancers (ALB) for Ingress.
- **External DNS** (optional): Automatically manages Route53 DNS records for Ingress resources.
- **Nginx Demo**: A sample "Hello World" deployment to verify the stack.

### Frontend Infrastructure (CloudFront)
- **S3 Bucket**: Stores static frontend files with versioning enabled
- **CloudFront Distribution**: Global CDN with custom domain support
- **Origin Access Control (OAC)**: Secure S3 access preventing direct public access
- **Route53 DNS Record**: A record pointing custom domain to CloudFront
- **Automatic Deployment**: Terraform provisioner syncs frontend files and invalidates cache

## External Dependencies

This Terraform configuration **references but does not create** the following resources. These must exist before running `terraform apply`:

| Resource | Variable | Description |
|----------|----------|-------------|
| **ACM Certificate** | `acm_certificate_arn` | SSL/TLS certificate for HTTPS on the ALB and CloudFront (must be in us-east-1) |
| **Route53 Hosted Zone** | `hosted_zone_id`, `hosted_zone_name` | DNS zone for the domain |
| **S3 State Bucket** | Configured in `state.tf` | Backend storage for Terraform state |

### Resources Created by Terraform
When enabled, the following resources are **created** by this configuration:
- **S3 Bucket** (CloudFront): Named `${cluster_name}-frontend` for static frontend files
- **CloudFront Distribution**: CDN for global content delivery
- **Route53 A Records**: DNS records for both backend (via external-dns) and frontend (via Terraform)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- An existing ACM certificate for your domain (must be in us-east-1 for CloudFront)
- A Route53 hosted zone for your domain

## Configuration Variables

### Required Variables
| Variable | Description |
|----------|-------------|
| `domain_name` | Domain for the EKS backend ingress (e.g., `app.example.com`) |
| `acm_certificate_arn` | ARN of ACM certificate (must be in us-east-1) |
| `hosted_zone_name` | Route53 hosted zone name (e.g., `example.com`) |
| `hosted_zone_id` | Route53 hosted zone ID |

### Optional Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for infrastructure |
| `cluster_name` | `eks-fargate-cluster` | Name of the EKS cluster |
| `kubernetes_version` | `1.28` | Kubernetes version |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `enable_external_dns` | `false` | Enable External DNS controller |
| `enable_cloudfront` | `false` | Enable CloudFront distribution for frontend |
| `frontend_domain_name` | `""` | Domain for CloudFront frontend (e.g., `ui.example.com`) |
| `frontend_api_url` | `""` | Backend API URL to inject into frontend (must be HTTPS) |

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

   # CloudFront Frontend Configuration (Optional)
   enable_cloudfront    = true
   frontend_domain_name = "ui.example.com"
   frontend_api_url     = "https://app.example.com"
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

## Outputs

After successful deployment, the following outputs are available:

### EKS Outputs
- `cluster_name` - Name of the EKS cluster
- `cluster_endpoint` - EKS cluster API endpoint
- `cluster_arn` - ARN of the EKS cluster
- `vpc_id` - VPC ID
- `private_subnet_ids` - Private subnet IDs
- `public_subnet_ids` - Public subnet IDs
- `kubeconfig_command` - Command to configure kubectl

### CloudFront Outputs (when enabled)
- `cloudfront_distribution_id` - CloudFront distribution ID
- `cloudfront_domain_name` - CloudFront distribution domain (*.cloudfront.net)
- `cloudfront_url` - Custom domain URL (e.g., https://ui.example.com)
- `frontend_s3_bucket` - S3 bucket name for frontend files

## Key Components

### AWS Load Balancer Controller
The configuration includes the necessary IAM roles and policies (IRSA) to allow the Load Balancer Controller to manage ALBs. It is deployed into the `kube-system` namespace.

### External DNS
When `enable_external_dns = true`, the external-dns controller is deployed to automatically create and manage Route53 DNS records based on Ingress annotations. This eliminates the need to manually create DNS records.

### CloudFront Distribution
When `enable_cloudfront = true`, the configuration provisions:

- **S3 Bucket**: Named `${cluster_name}-frontend`, stores static frontend files
- **CloudFront Distribution**: Global CDN with:
  - Custom domain support (via `frontend_domain_name`)
  - HTTPS using the existing ACM certificate
  - Origin Access Control (OAC) for secure S3 access
  - Custom error responses (404/403 → index.html)
  - Cache optimization (1 hour default, 1 year for assets)
- **Route53 A Record**: Points `frontend_domain_name` to CloudFront
- **Automatic Deployment**: `null_resource` provisioner that:
  - Syncs frontend files from `../../frontend/` to S3
  - Replaces `API_URL` in `app.js` with `frontend_api_url`
  - Invalidates CloudFront cache on changes

**Important Notes:**
- The ACM certificate must be in `us-east-1` (CloudFront requirement)
- Deployment takes 5-15 minutes due to CloudFront distribution creation
- Frontend files are automatically redeployed when they change

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

**Note**: CloudFront-related resources (S3 bucket, CloudFront distribution, Route53 A record for frontend) are managed by Terraform and will be destroyed when `enable_cloudfront = true`. The S3 bucket has `force_destroy = true`, so all objects will be deleted automatically.

### Manual Cleanup Steps

After running `terraform destroy`, verify and clean up these resources if needed:

1. **ALBs and Target Groups**: Check the EC2 console for any orphaned load balancers or target groups created by the ALB Controller.
2. **Route53 Records**: If using external-dns, verify DNS records were cleaned up in your hosted zone.
3. **CloudFront Cache**: CloudFront distributions may take up to 15 minutes to fully delete after `terraform destroy`.
