# Vanilla Express EKS

A full-stack application featuring a vanilla JavaScript frontend and an Express.js backend, designed for deployment on Amazon EKS using Terraform.

**Every line of code in this repository, as well as all of the documentation, was written by Claude and Gemini on the CLI. Trust but verify.**

## Project Structure

This repository is organized into three main components:

- **[backend/](./backend/)**: Node.js Express server providing a RESTful API for user management with JWT authentication, using local JSON files for data persistence.
- **[frontend/](./frontend/)**: A lightweight, vanilla HTML/CSS/JavaScript interface for interacting with the user management system, with full authentication support.
- **[ops/terraform/](./ops/terraform/)**: Infrastructure as Code (IaC) to provision the necessary AWS resources, including an EKS cluster, ALB ingress controller, and networking components.

## Architecture Overview

The application follows a standard client-server architecture:
1. The **Frontend** communicates with the **Backend** API via standard HTTP requests, using JWT tokens for authentication.
2. The **Backend** processes requests, authenticates users with JWT access/refresh tokens, and manages user data stored in `backend/data/users.json`. Authentication credentials are stored separately in `backend/data/auth-users.json`.
3. The **Infrastructure** layer sets up a production-ready Kubernetes environment on AWS, handling load balancing (ALB), DNS/SSL (ACM), and cluster management (EKS).

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
