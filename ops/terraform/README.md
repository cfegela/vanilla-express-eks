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
- **ACM Certificate**: Automated SSL/TLS certificate provisioning with DNS validation support.
- **AWS Load Balancer Controller**: Installed via Helm to manage Application Load Balancers (ALB) for Ingress.
- **Nginx Demo**: A sample "Hello World" deployment to verify the stack.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A registered domain name in AWS Route53 (optional, for automated DNS validation)

## Getting Started

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Configure Variables**:
   Create a `terraform.tfvars` file based on `terraform.tfvars.example`:
   ```hcl
   aws_region   = "us-east-1"
   cluster_name = "my-eks-cluster"
   domain_name  = "example.com"
   # Set to true if your domain is in Route53
   create_dns_records = true
   hosted_zone_name   = "example.com"
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

### CoreDNS Patch
Since this is a Fargate-only cluster, a `null_resource` is used to patch the `coredns` deployment to remove the default EC2 compute type annotation, allowing it to run on Fargate.

### SSL/TLS
Ingress is configured to use the provisioned ACM certificate and enforces SSL redirection by default.

## Cleanup

To destroy the provisioned infrastructure:
```bash
terraform destroy
```
