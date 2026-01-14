# Vanilla + Express + EKS

A full-stack application featuring a vanilla JavaScript frontend and an Express.js backend, designed for deployment on Amazon EKS using Terraform.

**Every line of code in this repository, as well as all of the documentation, was written by Claude and Gemini on the CLI. Trust but verify.**

## Project Structure

This repository is organized into three main components:

- **[backend/](./backend/)**: Node.js Express server providing a RESTful API for user management with JWT authentication, using local JSON files for data persistence.
- **[frontend/](./frontend/)**: A lightweight, vanilla HTML/CSS/JavaScript interface for interacting with the user management system, with full authentication support.
- **[ops/terraform/](./ops/terraform/)**: Infrastructure as Code (IaC) to provision the necessary AWS resources, including an EKS cluster, ALB ingress controller, and networking components.

## Architecture Overview

The application follows a standard client-server architecture with cloud-native deployment:
1. The **Frontend** is deployed as a static site via AWS CloudFront and S3, providing global CDN distribution with low latency.
2. The **Frontend** communicates with the **Backend** API via standard HTTP requests, using JWT tokens for authentication.
3. The **Backend** is deployed on Amazon EKS with Fargate, processing requests, authenticating users with JWT access/refresh tokens, and managing user data stored in `backend/data/users.json`. Authentication credentials are stored separately in `backend/data/auth-users.json`.
4. The **Infrastructure** layer sets up a production-ready Kubernetes environment on AWS, handling load balancing (ALB), DNS/SSL (ACM), cluster management (EKS), and CloudFront CDN distribution for the frontend.

## Getting Started

### Quick Start with Docker

The easiest way to run the full stack is with Docker Compose:

```bash
# Create backend environment file
cp backend/.env.example backend/.env
# Edit backend/.env with your JWT secrets

# Start both frontend and backend
docker-compose up --build
```

The frontend will be available at `http://localhost:80` and the backend API at `http://localhost:3000`.

### Component Documentation

For more details, refer to the specific documentation in each directory:

1. **Development**: See the `backend` and `frontend` READMEs for local setup and development instructions.
2. **Deployment**: See the `ops/terraform` README for details on provisioning the AWS infrastructure and deploying the application to EKS.

## Prerequisites

- Docker and Docker Compose (for containerized deployment)
- Node.js (for local backend development)
- Terraform (for infrastructure provisioning)
- AWS CLI configured with appropriate permissions
- kubectl (for cluster management)

## Production Deployment

The infrastructure supports production deployment on AWS with the following features:

### CloudFront Frontend Distribution
- Static frontend assets are deployed to S3 and distributed globally via CloudFront
- HTTPS enabled with custom domain support via ACM certificates
- Automatic cache invalidation on deployments
- API URL is automatically configured during deployment

### EKS Backend Deployment
- Backend API runs on Amazon EKS with Fargate (serverless containers)
- Application Load Balancer for ingress traffic
- External DNS for automatic Route53 DNS record management
- SSL/TLS termination at the load balancer

See the [ops/terraform README](./ops/terraform/README.md) for detailed deployment instructions.
