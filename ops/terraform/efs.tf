# =============================================================================
# AWS EFS (Elastic File System) for Backend Persistent Storage
# =============================================================================

# EFS File System
resource "aws_efs_file_system" "backend" {
  count          = var.enable_backend ? 1 : 0
  creation_token = "${var.cluster_name}-backend-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.cluster_name}-backend-efs"
  }
}

# Security Group for EFS Mount Targets
resource "aws_security_group" "efs" {
  count       = var.enable_backend ? 1 : 0
  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}

# EFS Mount Targets (one per private subnet for high availability)
resource "aws_efs_mount_target" "backend" {
  count           = var.enable_backend ? length(aws_subnet.private) : 0
  file_system_id  = aws_efs_file_system.backend[0].id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs[0].id]
}

# =============================================================================
# NOTE: EFS CSI Driver is not compatible with Fargate (requires privileged mode)
# Instead, we use static EFS provisioning with NFS mounts directly in pods
# =============================================================================

# =============================================================================
# NOTE: For Fargate, EFS is mounted directly in pod spec (no PV/PVC needed)
# Fargate doesn't support NFS PVs and CSI driver requires privileged mode
# =============================================================================
