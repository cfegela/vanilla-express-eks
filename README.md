# Vanilla Express EKS

A full-stack application featuring a vanilla JavaScript frontend and an Express.js backend, designed for deployment on Amazon EKS using Terraform.

## Project Structure

This repository is organized into three main components:

- **[backend/](./backend/)**: Node.js Express server providing a RESTful API for user management, using a local JSON file for data persistence.
- **[frontend/](./frontend/)**: A lightweight, vanilla HTML/CSS/JavaScript interface for interacting with the user management system.
- **[ops/terraform/](./ops/terraform/)**: Infrastructure as Code (IaC) to provision the necessary AWS resources, including an EKS cluster, ALB ingress controller, and networking components.

## Architecture Overview

The application follows a standard client-server architecture:
1. The **Frontend** communicates with the **Backend** API via standard HTTP requests.
2. The **Backend** processes requests and manages user data stored in `backend/data/users.json`.
3. The **Infrastructure** layer sets up a production-ready Kubernetes environment on AWS, handling load balancing (ALB), DNS/SSL (ACM), and cluster management (EKS).

## Getting Started

To explore or deploy this project, please refer to the specific documentation in each directory:

1. **Development**: See the `backend` and `frontend` READMEs for local setup and development instructions.
2. **Deployment**: See the `ops/terraform` README for details on provisioning the AWS infrastructure and deploying the application to EKS.

## Prerequisites

- Node.js (for backend development)
- Terraform (for infrastructure provisioning)
- AWS CLI configured with appropriate permissions
- kubectl (for cluster management)
