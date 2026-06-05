# The Complete Terraform & Terragrunt Tutorial

> From zero to production-grade multi-cloud infrastructure. Covers Terraform, Terragrunt, AWS, Azure, local Docker, Kubernetes (EKS/ECS), Ansible, and complex workloads (Kafka, Zookeeper, NiFi, Grafana/Prometheus/OTel, load balancing, fault tolerance, OpenSearch). Includes team patterns for shared, layered modules.

-----

## Table of Contents

1. [Core Concepts & Mental Model](#1-core-concepts--mental-model)
1. [Installation & Tooling](#2-installation--tooling)
1. [Terraform Fundamentals](#3-terraform-fundamentals)
1. [State, Backends & Locking](#4-state-backends--locking)
1. [Modules: Building Reusable Blocks](#5-modules-building-reusable-blocks)
1. [Local Docker Lab (No Cloud Bill)](#6-local-docker-lab)
1. [AWS Foundations](#7-aws-foundations)
1. [Azure Foundations](#8-azure-foundations)
1. [Terragrunt: DRY, Layered, Multi-Env](#9-terragrunt-dry-layered-multi-env)
1. [Team Patterns: Shared & Layered Templates](#10-team-patterns-shared--layered-templates)
1. [Kubernetes & EKS](#11-kubernetes--eks)
1. [AWS ECS (Fargate)](#12-aws-ecs-fargate)
1. [Ansible Integration](#13-ansible-integration)
1. [Workloads: Kafka, Zookeeper, NiFi](#14-workloads-kafka-zookeeper-nifi)
1. [Observability: Prometheus, Grafana, OpenTelemetry](#15-observability)
1. [Load Balancing, Proxies & Fault Tolerance](#16-load-balancing-proxies--fault-tolerance)
1. [OpenSearch Cluster](#17-opensearch-cluster)
1. [CI/CD, Testing & Best Practices](#18-cicd-testing--best-practices)
1. [Troubleshooting & Cheat Sheet](#19-troubleshooting--cheat-sheet)

-----

## 1. Core Concepts & Mental Model

**Terraform** is an Infrastructure as Code (IaC) tool. You declare *what* you want (desired state) in `.tf` files; Terraform figures out *how* to create, change, or destroy resources to match.

|Concept        |Meaning                                                                   |
|---------------|--------------------------------------------------------------------------|
|**Provider**   |A plugin that talks to an API (AWS, Azure, Docker, Kubernetes, Helm).     |
|**Resource**   |A single infrastructure object (`aws_instance`, `azurerm_resource_group`).|
|**Data source**|Read-only lookup of existing infrastructure.                              |
|**State**      |Terraform’s record of what it manages (`terraform.tfstate`).              |
|**Module**     |A reusable, parameterized package of resources.                           |
|**Plan/Apply** |`plan` = preview diff; `apply` = execute it.                              |

**Terragrunt** is a thin wrapper around Terraform that solves repetition: DRY backends, DRY provider config, managing many environments/regions, and orchestrating dependencies between modules. Use Terraform for *modules*; use Terragrunt for *wiring environments together*.

The golden workflow:

```bash
terraform init      # download providers, configure backend
terraform fmt       # format code
terraform validate  # check syntax/types
terraform plan      # preview changes
terraform apply     # make it real
terraform destroy   # tear it down
```

-----

## 2. Installation & Tooling

### macOS / Linux (recommended: tenv version manager)

```bash
# macOS
brew install tenv

# Linux
curl -fsSL https://raw.githubusercontent.com/tofuutils/tenv/main/install.sh | bash

# Install + use a specific Terraform version
tenv tf install 1.9.5
tenv tf use 1.9.5

# Terragrunt
tenv tg install 0.67.0
tenv tg use 0.67.0
```

### Verify

```bash
terraform version
terragrunt --version
```

### Supporting tools

```bash
# CLIs for the clouds you'll use
brew install awscli azure-cli kubectl helm ansible
# Linters / security scanners
brew install tflint tfsec trivy checkov pre-commit
```

### VS Code

Install the **HashiCorp Terraform** extension for syntax highlighting, autocomplete, and `terraform fmt` on save.

-----

## 3. Terraform Fundamentals

### 3.1 Your first configuration

A Terraform project is just a directory of `.tf` files. Conventional layout:

```
project/
├── main.tf         # resources
├── variables.tf    # inputs
├── outputs.tf      # outputs
├── providers.tf    # provider config
├── versions.tf     # version pins
└── terraform.tfvars # values (gitignore secrets!)
```

**versions.tf** — always pin versions:

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
```

### 3.2 Variables

**variables.tf**

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "tags" {
  type = map(string)
  default = {
    managed_by = "terraform"
  }
}
```

Pass values via `terraform.tfvars`, `-var`, `-var-file`, or `TF_VAR_*` env vars.

### 3.3 Outputs

```hcl
output "container_name" {
  description = "Name of the running container"
  value       = docker_container.app.name
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true   # hidden in CLI output
}
```

### 3.4 Locals, expressions & functions

```hcl
locals {
  name_prefix = "${var.environment}-myapp"
  common_tags = merge(var.tags, {
    environment = var.environment
    timestamp   = formatdate("YYYY-MM-DD", timestamp())
  })
}
```

Common functions: `merge`, `concat`, `lookup`, `coalesce`, `for`, `templatefile`, `jsonencode`, `cidrsubnet`, `try`.

### 3.5 Meta-arguments: count vs for_each

```hcl
# count → list-indexed (good for identical copies)
resource "docker_container" "worker" {
  count = var.instance_count
  name  = "worker-${count.index}"
  image = docker_image.app.image_id
}

# for_each → keyed (good for distinct named resources; safer for edits)
resource "docker_container" "service" {
  for_each = toset(["api", "web", "cache"])
  name     = "svc-${each.key}"
  image    = docker_image.app.image_id
}
```

**Rule of thumb:** prefer `for_each` — removing an item from a `count` list re-indexes and destroys/recreates resources.

### 3.6 Dynamic blocks

```hcl
resource "docker_container" "app" {
  name  = "app"
  image = docker_image.app.image_id
  dynamic "ports" {
    for_each = var.exposed_ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }
}
```

-----

## 4. State, Backends & Locking

State maps your config to real-world resources. **Never edit it by hand.** For teams, store it remotely with locking so two people can’t apply simultaneously.

### 4.1 AWS S3 backend (with native locking)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket       = "mycompany-tfstate"
    key          = "prod/network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true   # S3-native locking (TF ≥ 1.10, no DynamoDB needed)
  }
}
```

### 4.2 Azure backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "mycotfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### 4.3 State commands

```bash
terraform state list                 # list managed resources
terraform state show aws_vpc.main     # inspect one
terraform state mv  A B               # rename/move
terraform state rm  aws_instance.old  # stop managing (doesn't destroy)
terraform import aws_vpc.main vpc-123  # adopt existing resource
```

> **Tip:** Keep one state per environment per layer (network, data, app). Small blast radius = safer applies.

-----

## 5. Modules: Building Reusable Blocks

A module is any directory with `.tf` files. Calling a module:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  tags = local.common_tags
}
```

### Authoring your own module

```
modules/web-app/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

Module sources can be local (`./modules/x`), Git (`git::https://...//path?ref=v1.2.0`), or a registry. **Always pin `?ref=` or `version`** for reproducibility.

-----

## 6. Local Docker Lab

Start here — no cloud account, no bill, instant feedback.

### 6.1 Provider + a real stack (app + Postgres + Redis)

```hcl
# versions.tf
terraform {
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
    random = { source = "hashicorp/random",   version = "~> 3.6" }
  }
}

# providers.tf
provider "docker" {}

# main.tf
resource "docker_network" "app" {
  name = "app-net"
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "docker_image" "postgres" {
  name = "postgres:16-alpine"
}

resource "docker_container" "db" {
  name  = "app-db"
  image = docker_image.postgres.image_id
  networks_advanced { name = docker_network.app.name }
  env = [
    "POSTGRES_PASSWORD=${random_password.db.result}",
    "POSTGRES_DB=appdb",
  ]
  ports {
    internal = 5432
    external = 5432
  }
}

resource "docker_image" "redis" {
  name = "redis:7-alpine"
}

resource "docker_container" "cache" {
  name  = "app-cache"
  image = docker_image.redis.image_id
  networks_advanced { name = docker_network.app.name }
}
```

```bash
terraform init && terraform apply
docker ps        # see your containers
terraform destroy
```

You now understand the full loop. Everything else is bigger providers and more resources.

-----

## 7. AWS Foundations

### 7.1 Provider & authentication

```hcl
# versions.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

# providers.tf
provider "aws" {
  region = var.region
  default_tags { tags = local.common_tags }
}
```

Auth options (best → worst): IAM roles / OIDC in CI, `aws sso login`, named profiles, env vars (`AWS_ACCESS_KEY_ID`). **Never hardcode keys in `.tf`.**

### 7.2 A complete network + compute example

```hcl
# VPC via official module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"
  name    = "${var.environment}-vpc"
  cidr    = "10.0.0.0/16"
  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = var.environment != "prod"
}

# Security group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx && systemctl enable --now nginx
  EOF
}
```

### 7.3 Common AWS building blocks

```hcl
# S3 bucket (private, versioned, encrypted)
resource "aws_s3_bucket" "data" {
  bucket = "${var.environment}-myco-data"
}
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" } }
}

# RDS Postgres
resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-db"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_subnet_group_name = aws_db_subnet_group.main.name
  multi_az             = var.environment == "prod"
  storage_encrypted    = true
  skip_final_snapshot  = var.environment != "prod"
  username             = "appuser"
  password             = random_password.db.result
}
```

-----

## 8. Azure Foundations

### 8.1 Provider & auth

```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

Auth: `az login` for local; service principal or workload identity federation (OIDC) for CI.

### 8.2 Resource group, network, VM

```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "${var.environment}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.app.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
```

### 8.3 Multi-cloud in one config

Use provider aliases when a single stack spans clouds:

```hcl
provider "aws"     { region = "us-east-1" }
provider "azurerm" { features {} }
# Resources reference whichever provider applies; outputs from one can feed the other
```

-----

## 9. Terragrunt: DRY, Layered, Multi-Env

Terragrunt removes copy-paste across environments. Core ideas: a root `terragrunt.hcl` defines the backend + provider *once*; each leaf folder points to a module and supplies inputs; `dependency` blocks wire outputs between layers.

### 9.1 Repository layout

```
infra-live/
├── terragrunt.hcl                # root: remote_state + generate provider
├── env.hcl                       # (optional) shared env vars
├── _envcommon/                   # shared input templates per component
│   └── vpc.hcl
├── dev/
│   ├── env.hcl
│   ├── network/terragrunt.hcl
│   ├── data/terragrunt.hcl
│   └── app/terragrunt.hcl
├── staging/ ...
└── prod/
    ├── env.hcl
    ├── network/terragrunt.hcl
    ├── data/terragrunt.hcl
    └── app/terragrunt.hcl
```

### 9.2 Root terragrunt.hcl — backend + provider generated for every child

```hcl
# infra-live/terragrunt.hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.environment
  region   = local.env_vars.locals.region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "myco-tfstate-${local.region}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags { tags = { environment = "${local.env}", managed_by = "terragrunt" } }
}
EOF
}
```

### 9.3 An environment file

```hcl
# infra-live/prod/env.hcl
locals {
  environment = "prod"
  region      = "us-east-1"
}
```

### 9.4 A leaf module config with dependencies

```hcl
# infra-live/prod/app/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/myco/tf-modules.git//app?ref=v2.3.1"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id          = "vpc-fake"
    private_subnets = ["subnet-fake1", "subnet-fake2"]
  }
}

dependency "data" {
  config_path = "../data"
  mock_outputs = { db_endpoint = "fake.rds.amazonaws.com" }
}

inputs = {
  vpc_id       = dependency.network.outputs.vpc_id
  subnet_ids   = dependency.network.outputs.private_subnets
  db_endpoint  = dependency.data.outputs.db_endpoint
  instance_type = "t3.medium"
  desired_count = 4
}
```

### 9.5 Running Terragrunt

```bash
cd infra-live/prod/app
terragrunt plan
terragrunt apply

# Whole environment at once, respecting dependency order:
cd infra-live/prod
terragrunt run-all plan
terragrunt run-all apply
```

`run-all` builds a DAG from `dependency` blocks and applies network → data → app automatically.

-----

## 10. Team Patterns: Shared & Layered Templates

The biggest real-world win is **reuse without copy-paste**. Three layers:

```
┌─────────────────────────────────────────────┐
│ infra-live (Terragrunt)  → env wiring + inputs │  ← changes often, per-team
├─────────────────────────────────────────────┤
│ tf-modules (Terraform)   → reusable components │  ← versioned, shared
├─────────────────────────────────────────────┤
│ upstream registry modules (AWS/Azure official) │  ← pinned dependencies
└─────────────────────────────────────────────┘
```

### 10.1 Versioned shared module repo

Keep modules in a dedicated repo (`tf-modules`), tag releases with SemVer, and consume by `ref`:

```hcl
terraform {
  source = "git::https://github.com/myco/tf-modules.git//eks?ref=v1.8.2"
}
```

Teams upgrade on their own schedule by bumping the `ref`. Breaking changes → major version bump.

### 10.2 `_envcommon` pattern — share inputs, override per env

```hcl
# infra-live/_envcommon/vpc.hcl  (shared baseline)
locals {
  base_cidr = "10.0.0.0/16"
}
inputs = {
  enable_nat_gateway = true
  enable_dns_support = true
}
```

```hcl
# infra-live/prod/network/terragrunt.hcl
include "root"     { path = find_in_parent_folders() }
include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/vpc.hcl"
  expose = true
  merge_strategy = "deep"
}
inputs = {
  single_nat_gateway = false   # prod overrides: HA NAT
}
```

`dev` inherits the same baseline but sets `single_nat_gateway = true` to save cost. One source of truth, per-env overrides.

### 10.3 Governance guardrails

- **`tflint` + `tfsec`/`checkov`** in pre-commit and CI.
- **Required tags** enforced via `default_tags` and policy (e.g., OPA/Sentinel).
- **Module README + examples/** so consumers self-serve.
- **CODEOWNERS** on the modules repo; PR review required for releases.
- Pin provider + Terraform versions in every module’s `versions.tf`.

-----

## 11. Kubernetes & EKS

### 11.1 Provision an EKS cluster

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "${var.environment}-eks"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true   # IAM Roles for Service Accounts

  eks_managed_node_groups = {
    general = {
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
    spot = {
      min_size       = 0
      max_size       = 10
      desired_size   = 2
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
    }
  }
}
```

### 11.2 Wire the Kubernetes & Helm providers to the cluster

```hcl
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
```

```bash
aws eks update-kubeconfig --name dev-eks --region us-east-1
kubectl get nodes
```

### 11.3 Deploy workloads as code (Helm + raw manifests)

```hcl
# Ingress controller via Helm
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.11.2"
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# A namespace + deployment via the kubernetes provider
resource "kubernetes_namespace" "app" {
  metadata { name = "myapp" }
}

resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    replicas = 3
    selector { match_labels = { app = "api" } }
    template {
      metadata { labels = { app = "api" } }
      spec {
        container {
          name  = "api"
          image = "myco/api:1.4.0"
          port { container_port = 8080 }
          resources {
            requests = { cpu = "250m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
          readiness_probe {
            http_get { path = "/healthz", port = 8080 }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}
```

> **Pattern:** Use Terraform for the cluster + platform add-ons (ingress, cert-manager, autoscaler). Use GitOps (Argo CD/Flux) for app rollouts once the platform exists. Terraform can bootstrap Argo CD via Helm.

-----

## 12. AWS ECS (Fargate)

For container workloads without managing Kubernetes.

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([{
    name      = "app"
    image     = "myco/app:1.4.0"
    essential = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/app"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.app.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }
  # Roll deployments safely
  deployment_circuit_breaker { enable = true, rollback = true }
}
```

Pair with an ALB (see §16) and an `aws_appautoscaling_target` for scale-on-CPU.

-----

## 13. Ansible Integration

Terraform provisions infrastructure; **Ansible configures what runs on it**. Keep them separate and connect via a dynamic inventory.

### 13.1 Pattern A — Terraform writes inventory, then run Ansible

```hcl
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOF
    [web]
    %{ for ip in aws_instance.web[*].private_ip ~}
    ${ip}
    %{ endfor ~}

    [web:vars]
    ansible_user=ec2-user
    ansible_ssh_private_key_file=~/.ssh/id_rsa
  EOF
}
```

```bash
terraform apply
ansible-playbook -i inventory.ini site.yml
```

### 13.2 Pattern B — AWS dynamic inventory (no file generation)

Tag instances in Terraform, let Ansible discover them:

```hcl
resource "aws_instance" "web" {
  # ...
  tags = { Role = "web", Environment = var.environment }
}
```

```yaml
# inventory.aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions: [us-east-1]
keyed_groups:
  - key: tags.Role
    prefix: role
filters:
  tag:Environment: prod
```

```bash
ansible-inventory -i inventory.aws_ec2.yml --graph
ansible-playbook -i inventory.aws_ec2.yml site.yml
```

### 13.3 Example playbook

```yaml
# site.yml
- hosts: role_web
  become: true
  roles:
    - common
    - nginx
  tasks:
    - name: Ensure nginx running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

> **Anti-pattern:** Avoid `local-exec` calling Ansible inside Terraform for anything beyond a quick lab — it breaks idempotency and plan/apply semantics. Orchestrate them as separate CI stages instead.

-----

## 14. Workloads: Kafka, Zookeeper, NiFi

Two deployment strategies: **managed** (AWS MSK, fastest to production) or **self-managed on Kubernetes** (portable, full control via Helm). Examples for both.

### 14.1 Managed Kafka — AWS MSK

```hcl
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.environment}-kafka"
  kafka_version          = "3.7.x"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = module.vpc.private_subnets
    security_groups = [aws_security_group.kafka.id]
    storage_info {
      ebs_storage_info { volume_size = 100 }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter  { enabled_in_broker = true }
      node_exporter { enabled_in_broker = true }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs { enabled = true, log_group = aws_cloudwatch_log_group.kafka.name }
    }
  }
}
```

MSK manages Zookeeper/KRaft for you. Outputs (`bootstrap_brokers_tls`) feed your apps.

### 14.2 Self-managed on Kubernetes (Helm via Terraform)

Modern Kafka uses **KRaft** (no Zookeeper). For legacy/learning, Zookeeper is shown too.

```hcl
resource "kubernetes_namespace" "streaming" {
  metadata { name = "streaming" }
}

# Kafka (Bitnami chart — KRaft mode by default in recent versions)
resource "helm_release" "kafka" {
  name       = "kafka"
  namespace  = kubernetes_namespace.streaming.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = "30.1.4"

  values = [yamlencode({
    controller = { replicaCount = 3 }
    broker     = { replicaCount = 3 }
    kraft      = { enabled = true }
    metrics    = {
      kafka = { enabled = true }       # exposes Prometheus metrics
      jmx   = { enabled = true }
    }
    persistence = { size = "50Gi" }
  })]
}
```

Legacy Zookeeper (only if you must run Kafka < KRaft):

```hcl
resource "helm_release" "zookeeper" {
  name       = "zookeeper"
  namespace  = kubernetes_namespace.streaming.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "zookeeper"
  version    = "13.4.2"
  values = [yamlencode({
    replicaCount = 3
    persistence  = { size = "10Gi" }
    metrics      = { enabled = true }
  })]
}
```

### 14.3 Apache NiFi (dataflow)

```hcl
resource "helm_release" "nifi" {
  name       = "nifi"
  namespace  = kubernetes_namespace.streaming.metadata[0].name
  repository = "https://cetic.github.io/helm-nifi"
  chart      = "nifi"
  version    = "1.2.1"
  values = [yamlencode({
    replicaCount = 3
    persistence  = { enabled = true, size = "20Gi" }
    auth         = { singleUser = { username = "admin", password = random_password.nifi.result } }
    zookeeper    = { enabled = true }   # NiFi clustering uses ZK for coordination
    metrics      = { prometheus = { enabled = true } }
  })]
}

resource "random_password" "nifi" {
  length  = 16
  special = true
}
```

> **Tip:** Pull connection details (broker addresses, topics) as Terraform outputs and feed them into NiFi processor configs or downstream app env vars to keep the whole pipeline declarative.

-----

## 15. Observability

The standard stack: **Prometheus** (metrics scraping/storage), **Grafana** (dashboards), **OpenTelemetry Collector** (traces/metrics/logs pipeline). On Kubernetes the easiest path is `kube-prometheus-stack` plus the OTel operator.

### 15.1 Prometheus + Grafana + Alertmanager (one chart)

```hcl
resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kps"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.3.0"

  values = [yamlencode({
    grafana = {
      adminPassword = random_password.grafana.result
      service       = { type = "LoadBalancer" }
      defaultDashboardsEnabled = true
    }
    prometheus = {
      prometheusSpec = {
        retention                               = "15d"
        serviceMonitorSelectorNilUsesHelmValues = false  # auto-discover ServiceMonitors
        storageSpec = {
          volumeClaimTemplate = {
            spec = { resources = { requests = { storage = "100Gi" } } }
          }
        }
      }
    }
    alertmanager = { enabled = true }
  })]
}

resource "random_password" "grafana" {
  length  = 20
  special = false
}
```

Because `serviceMonitorSelectorNilUsesHelmValues = false`, the Kafka/NiFi charts above (with `metrics.enabled = true`) are scraped automatically once they expose a `ServiceMonitor`.

### 15.2 OpenTelemetry Collector

```hcl
resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.108.0"

  values = [yamlencode({
    mode = "deployment"
    config = {
      receivers = {
        otlp = { protocols = { grpc = {}, http = {} } }
      }
      processors = {
        batch          = {}
        memory_limiter = { check_interval = "1s", limit_percentage = 80 }
      }
      exporters = {
        prometheus = { endpoint = "0.0.0.0:8889" }
        # otlphttp  = { endpoint = "https://your-tracing-backend" }
      }
      service = {
        pipelines = {
          traces  = { receivers = ["otlp"], processors = ["batch"], exporters = ["otlphttp"] }
          metrics = { receivers = ["otlp"], processors = ["batch"], exporters = ["prometheus"] }
        }
      }
    }
  })]
}
```

Apps send OTLP to `otel-collector:4317`; the collector fans out metrics to Prometheus and traces to your tracing backend. Visualize everything in Grafana.

-----

## 16. Load Balancing, Proxies & Fault Tolerance

### 16.1 AWS Application Load Balancer (multi-AZ, health checks)

```hcl
resource "aws_lb" "app" {
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets   # spread across AZs
  security_groups    = [aws_security_group.alb.id]
  enable_deletion_protection = var.environment == "prod"
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
  deregistration_delay = 30
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.app.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### 16.2 Fault tolerance — Auto Scaling + multi-AZ

```hcl
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg"
  min_size            = 3
  max_size            = 12
  desired_capacity    = 4
  vpc_zone_identifier = module.vpc.private_subnets   # multiple AZs
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50 }
  }
}

# Scale on CPU
resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 60
  }
}
```

**Fault-tolerance checklist:** multi-AZ subnets, ≥3 replicas, ELB health checks, rolling instance refresh, RDS Multi-AZ, cross-AZ load balancing, circuit breakers on ECS deployments, and graceful deregistration delays.

### 16.3 Reverse proxy / service mesh proxies on Kubernetes

```hcl
# Envoy-based ingress / API gateway via Helm (example: Kong)
resource "helm_release" "kong" {
  name       = "kong"
  namespace  = "kong"
  create_namespace = true
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = "2.41.1"
  values = [yamlencode({
    proxy = { type = "LoadBalancer" }
    replicaCount = 3
  })]
}
```

For L7 retries, timeouts, and mTLS between services, add a mesh (Istio/Linkerd) the same way — all as `helm_release` resources, all versioned in Git.

-----

## 17. OpenSearch Cluster

### 17.1 Managed — AWS OpenSearch Service

```hcl
resource "aws_opensearch_domain" "logs" {
  domain_name    = "${var.environment}-logs"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type            = "m6g.large.search"
    instance_count           = 3
    zone_awareness_enabled   = true                     # spread across AZs
    zone_awareness_config { availability_zone_count = 3 }
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    dedicated_master_count   = 3
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }

  vpc_options {
    subnet_ids         = slice(module.vpc.private_subnets, 0, 3)
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest        { enabled = true }
  node_to_node_encryption { enabled = true }
  domain_endpoint_options { enforce_https = true, tls_security_policy = "Policy-Min-TLS-1-2-2019-07" }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch.result
    }
  }
}
```

The `zone_awareness` + dedicated masters give you fault tolerance; feed logs in via the OTel collector or Fluent Bit and visualize in OpenSearch Dashboards (or Grafana).

### 17.2 Self-managed on Kubernetes

```hcl
resource "helm_release" "opensearch" {
  name       = "opensearch"
  namespace  = "logging"
  create_namespace = true
  repository = "https://opensearch-project.github.io/helm-charts"
  chart      = "opensearch"
  version    = "2.23.1"
  values = [yamlencode({
    replicas = 3
    persistence = { size = "100Gi" }
    resources   = { requests = { cpu = "1", memory = "2Gi" } }
  })]
}
```

-----

## 18. CI/CD, Testing & Best Practices

### 18.1 GitHub Actions pipeline (plan on PR, apply on merge, OIDC auth)

```yaml
name: terraform
on:
  pull_request: { paths: ["infra-live/**"] }
  push: { branches: [main], paths: ["infra-live/**"] }

permissions:
  id-token: write     # OIDC — no long-lived AWS keys
  contents: read
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/gha-terraform
          aws-region: us-east-1
      - uses: gruntwork-io/terragrunt-action@v2
        with:
          tg_version: "0.67.0"
          tf_version: "1.9.5"
          tg_dir: "infra-live/prod"
          tg_command: "run-all plan"
```

### 18.2 Testing

```bash
terraform fmt -check -recursive
terraform validate
tflint --recursive
tfsec . || checkov -d .
# Native test framework (TF ≥ 1.6):
terraform test            # runs *.tftest.hcl
```

A native test:

```hcl
# tests/network.tftest.hcl
run "vpc_has_correct_cidr" {
  command = plan
  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR mismatch"
  }
}
```

### 18.3 Best practices checklist

- Pin **everything** (Terraform, providers, modules) to explicit versions.
- One state per environment per layer; remote backend with locking + encryption.
- `for_each` over `count`; descriptive resource names; consistent tagging.
- Never commit secrets — use AWS Secrets Manager / Azure Key Vault, `sensitive = true`, and `.gitignore` for `*.tfvars` with secrets.
- Small, composable, versioned modules in a shared repo; `_envcommon` for shared inputs.
- Run `plan` in CI on PRs; require review; `apply` only from `main` via OIDC.
- Use `pre-commit` with fmt/validate/tflint/tfsec hooks.
- Keep blast radius small; use `-target` only for emergencies.

-----

## 19. Troubleshooting & Cheat Sheet

### Common issues

|Symptom                       |Fix                                                                    |
|------------------------------|-----------------------------------------------------------------------|
|State lock stuck              |`terraform force-unlock <LOCK_ID>` (verify no one is applying).        |
|Drift (manual changes)        |`terraform plan` shows diff; `terraform apply` reconciles, or `import`.|
|Provider auth error           |Check `aws sts get-caller-identity` / `az account show`.               |
|Dependency cycle              |Break with explicit `depends_on` or restructure modules.               |
|Terragrunt mock outputs needed|Add `mock_outputs` to `dependency` for `plan` before deps exist.       |
|Resource needs replacement    |`terraform plan` shows `-/+`; use `-replace=ADDR` to force.            |

### Command cheat sheet

```bash
# Terraform
terraform init -upgrade
terraform plan -out=tf.plan && terraform apply tf.plan
terraform apply -replace="aws_instance.web"
terraform output -json
terraform state list | grep eks
terraform console            # interactive expression eval

# Terragrunt
terragrunt run-all plan
terragrunt run-all apply --terragrunt-non-interactive
terragrunt output -json
terragrunt graph-dependencies | dot -Tpng > deps.png

# Kubernetes (post-provision)
aws eks update-kubeconfig --name dev-eks --region us-east-1
kubectl get pods -A
helm list -A
```

### Learning path recap

1. **Local Docker** (§6) → grasp the loop with no cost.
1. **AWS or Azure basics** (§7–8) → real cloud resources.
1. **Modules** (§5) → stop repeating yourself.
1. **Terragrunt + layered teams** (§9–10) → multi-env at scale.
1. **EKS/ECS** (§11–12) → containers.
1. **Workloads + observability + LB/FT + OpenSearch** (§14–17) → production systems.
1. **CI/CD + testing** (§18) → ship safely.

-----

*End of tutorial. Each section is self-contained — copy a block, pin your versions, `terraform init`, and iterate.*