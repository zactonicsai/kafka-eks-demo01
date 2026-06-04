terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.60" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.32" }
    helm       = { source = "hashicorp/helm", version = "~> 2.15" }
    tls        = { source = "hashicorp/tls", version = "~> 4.0" }
  }

  # Remote state in S3 with native S3 state locking (Terraform 1.11+).
  # No DynamoDB table needed — `use_lockfile` makes S3 handle locking via
  # conditional writes (a small .tflock object next to the state file).
  backend "s3" {
    bucket         = "kafakademo-tfstate-bucket"
    key          = "kafka-eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# Pull a short-lived token to auth the K8s/Helm providers against EKS.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
