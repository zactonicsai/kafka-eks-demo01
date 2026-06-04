data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# 1) Network
module "vpc" {
  source          = "./modules/vpc"
  name            = var.name
  cidr_block      = "10.0.0.0/16"
  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  tags            = var.tags
}

# 2) EKS cluster + node group
module "eks" {
  source             = "./modules/eks"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = var.tags
}

# 3) Monitoring (Prometheus + Grafana) — installed before Kafka so the
#    PodMonitor CRDs exist when brokers come up.
module "monitoring" {
  source                 = "./modules/monitoring"
  grafana_admin_password = var.grafana_admin_password
  depends_on             = [module.eks]
}

# 4) Kafka via Strimzi
# NOTE: on a fresh cluster, apply the Strimzi operator first so its CRDs exist
# before the Kafka custom resources are planned. See README "two-phase apply".
module "kafka" {
  source     = "./modules/kafka"
  name       = var.name
  depends_on = [module.eks, module.monitoring]
}
