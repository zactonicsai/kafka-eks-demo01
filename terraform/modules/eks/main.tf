# ---------------------------------------------------------------------------
# EKS control plane + managed node group.
# Security choices:
#   * Private API endpoint, public endpoint locked to your CIDR.
#   * Secrets envelope-encrypted with a dedicated KMS key.
#   * Control-plane audit/auth logs shipped to CloudWatch.
#   * IRSA (IAM Roles for Service Accounts) enabled via OIDC provider.
# ---------------------------------------------------------------------------

# KMS key used to envelope-encrypt Kubernetes Secrets at rest.
resource "aws_kms_key" "eks" {
  description             = "${var.name} EKS secret envelope encryption"
  enable_key_rotation     = true # auto-rotate yearly (best practice)
  deletion_window_in_days = 7
  tags                    = var.tags
}

# IAM role assumed by the EKS control plane itself.
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Security group for the control plane <-> node communication.
resource "aws_security_group" "cluster" {
  name        = "${var.name}-eks-cluster-sg"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-eks-cluster-sg" })
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true  # nodes reach API over private network
    endpoint_public_access  = true  # kubectl from CI; lock down via CIDR below
    public_access_cidrs     = ["0.0.0.0/0"] # NOTE: replace with your office/CI CIDR
  }

  # Envelope-encrypt all Kubernetes secrets with our KMS key.
  encryption_config {
    provider { key_arn = aws_kms_key.eks.arn }
    resources = ["secrets"]
  }

  # Ship every control-plane log type to CloudWatch for auditing.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags       = var.tags
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# OIDC provider: foundation of IRSA so pods get scoped IAM roles (no node-wide creds).
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# ---- Managed node group --------------------------------------------------
resource "aws_iam_role" "node" {
  name = "${var.name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}

# Minimum policies a worker node needs.
resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids # nodes ONLY in private subnets
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1 # rolling, zero-downtime updates
  }

  tags = var.tags
  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}
