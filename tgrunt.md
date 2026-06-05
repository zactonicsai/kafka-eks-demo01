# Complete Terraform + Terragrunt Tutorial for Team Infrastructure Templates

**Audience:** Beginners, team leads, DevOps/SRE engineers, cloud engineers, and application teams who need reusable infrastructure templates for AWS, Azure, local Docker, Kubernetes, EKS, ECS, observability, Kafka, ZooKeeper, NiFi, OpenSearch, load balancing, fault tolerance, and shared team standards.

**Goal:** Learn how to build infrastructure as code from simple local examples to layered team templates that support real applications and platform services.

---

## Table of Contents

1. What Terraform and Terragrunt Do
2. Beginner Mental Model
3. Install Tools on Windows, macOS, and Linux
4. Terraform Basics
5. Terraform File Types
6. First Local Docker Example
7. Variables, Outputs, and Locals
8. State, Backends, and Locking
9. Modules and Team Templates
10. Recommended Team Repository Layout
11. Terragrunt Basics
12. Terragrunt Live Infrastructure Layout
13. AWS Foundation Example
14. AWS ECS Example
15. AWS EKS and Kubernetes Example
16. Azure Foundation Example
17. Azure AKS Example
18. Local Docker Platform Example
19. Kafka, ZooKeeper/KRaft, and NiFi Patterns
20. Grafana, Prometheus, OpenTelemetry, and Logs
21. Load Balancing, Proxies, and Fault Tolerance
22. OpenSearch Pattern
23. Ansible with Terraform and Terragrunt
24. CI/CD Pipeline Examples
25. Security Best Practices
26. Testing and Validation
27. Cost Controls
28. Team Template Governance
29. Beginner-to-Advanced Learning Path
30. Full Example Repository Skeleton
31. Common Troubleshooting
32. Official References

---

# 1. What Terraform and Terragrunt Do

## Terraform

Terraform is an infrastructure as code tool. Instead of clicking around in AWS, Azure, or another console, you write files that describe the infrastructure you want. Terraform then compares your desired configuration to the real environment and creates, updates, or deletes resources.

Terraform can manage:

- AWS VPCs, EC2, ECS, EKS, IAM, S3, RDS, OpenSearch, ALB, Route 53
- Azure resource groups, virtual networks, AKS, App Service, storage accounts, Key Vault, Application Gateway
- Local Docker containers, networks, and volumes
- Kubernetes resources such as namespaces, deployments, services, Helm charts, and ingress
- Monitoring resources such as Grafana dashboards, Prometheus Helm charts, and OpenTelemetry Collector manifests

## Terragrunt

Terragrunt is a wrapper around Terraform. It helps teams avoid copy-and-paste Terraform code across environments. It is especially useful when you have many environments such as:

- dev
- test
- staging
- production
- multiple regions
- multiple cloud accounts or subscriptions
- many application teams

Terraform is the engine. Terragrunt is the organizer.

---

# 2. Beginner Mental Model

Think of infrastructure like building a neighborhood.

| Concept | Simple Meaning | Example |
|---|---|---|
| Provider | The company or platform Terraform talks to | AWS, Azure, Docker, Kubernetes |
| Resource | One thing Terraform creates | VPC, EC2, storage account, Docker container |
| Module | Reusable template | Standard VPC template |
| Variable | Input setting | region, environment, instance size |
| Output | Value returned after creation | load balancer URL |
| State | Terraform memory file | Tracks what Terraform created |
| Backend | Place where state is stored | S3, Azure Storage |
| Terragrunt live repo | Real environment config | prod/us-east-1/app1 |
| Terragrunt module repo | Shared reusable code | modules/aws/vpc |

---

# 3. Install Tools

## Required Tools

Install these first:

- Terraform or OpenTofu
- Terragrunt
- AWS CLI
- Azure CLI
- Docker Desktop
- kubectl
- Helm
- Git
- VS Code
- Ansible, optional but useful
- tflint
- tfsec or Checkov
- pre-commit

## Windows Setup

Use PowerShell as Administrator.

```powershell
winget install Hashicorp.Terraform
winget install Git.Git
winget install Microsoft.AzureCLI
winget install Amazon.AWSCLI
winget install Docker.DockerDesktop
winget install Kubernetes.kubectl
winget install Helm.Helm
```

Terragrunt may need manual install:

```powershell
mkdir C:\tools\terragrunt
# Download terragrunt.exe from the official Terragrunt release page
# Add C:\tools\terragrunt to your PATH
terragrunt --version
```

## macOS Setup

```bash
brew install terraform terragrunt awscli azure-cli kubectl helm git tflint checkov pre-commit
```

## Linux Setup

```bash
sudo apt-get update
sudo apt-get install -y unzip curl git
# Install Terraform, Terragrunt, AWS CLI, Azure CLI, Docker, kubectl, and Helm using official package instructions.
```

---

# 4. Terraform Basics

A small Terraform project usually has these files:

```text
my-terraform-project/
  main.tf
  variables.tf
  outputs.tf
  providers.tf
  versions.tf
  terraform.tfvars
```

## versions.tf

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

## providers.tf

```hcl
provider "aws" {
  region = var.aws_region
}
```

## variables.tf

```hcl
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name such as dev, test, stage, prod"
  type        = string
}
```

## main.tf

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-team-${var.environment}-example-bucket-12345"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

## outputs.tf

```hcl
output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}
```

## terraform.tfvars

```hcl
environment = "dev"
aws_region  = "us-east-1"
```

## Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

### What each command means

| Command | Purpose |
|---|---|
| terraform init | Downloads providers and sets up backend |
| terraform fmt | Formats code |
| terraform validate | Checks syntax |
| terraform plan | Shows what will happen |
| terraform apply | Creates or changes resources |
| terraform destroy | Deletes resources |

---

# 5. Terraform File Types

Terraform does not require exact file names, but teams should standardize them.

| File | Purpose |
|---|---|
| versions.tf | Terraform version and provider versions |
| providers.tf | Provider configuration |
| main.tf | Main resources |
| variables.tf | Inputs |
| outputs.tf | Outputs |
| locals.tf | Local calculated values |
| data.tf | Existing resources to read |
| backend.tf | Remote state backend |
| terraform.tfvars | Environment-specific values |

---

# 6. First Local Docker Example

This is a safe beginner example because it runs locally.

## Folder

```text
examples/docker-nginx/
  versions.tf
  main.tf
  outputs.tf
```

## versions.tf

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
```

## main.tf

```hcl
resource "docker_network" "app" {
  name = "tf-demo-network"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  name  = "tf-demo-nginx"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app.name
  }

  ports {
    internal = 80
    external = 8080
  }
}
```

## outputs.tf

```hcl
output "url" {
  value = "http://localhost:8080"
}
```

## Run

```bash
terraform init
terraform plan
terraform apply
```

Open:

```text
http://localhost:8080
```

Destroy:

```bash
terraform destroy
```

---

# 7. Variables, Outputs, and Locals

## Variables

Variables make templates configurable.

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

## Locals

Locals calculate common values once.

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

## Outputs

Outputs pass information to users, CI/CD pipelines, and other modules.

```hcl
output "name_prefix" {
  value = local.name_prefix
}
```

---

# 8. State, Backends, and Locking

Terraform state is critical. It maps your code to real infrastructure.

Do not store production state only on your laptop. Use remote state.

## AWS S3 Backend Example

```hcl
terraform {
  backend "s3" {
    bucket       = "my-company-terraform-state"
    key          = "dev/network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

## Azure Backend Example

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatecompany123"
    container_name       = "tfstate"
    key                  = "dev/network/terraform.tfstate"
  }
}
```

## Backend Rules

- Keep one state file per environment and layer.
- Do not share one huge state file across everything.
- Enable encryption.
- Enable locking where supported.
- Limit who can read state because secrets may appear in state.
- Back up state.

Recommended state layers:

```text
dev/network
dev/security
dev/eks
dev/apps/kafka
dev/apps/nifi
prod/network
prod/security
prod/eks
prod/apps/kafka
prod/apps/nifi
```

---

# 9. Modules and Team Templates

A module is a reusable Terraform template.

## Simple Module Layout

```text
modules/
  aws/
    vpc/
      versions.tf
      variables.tf
      main.tf
      outputs.tf
    ecs-service/
    eks-cluster/
    rds-postgres/
    opensearch/
  azure/
    network/
    aks-cluster/
    app-service/
    key-vault/
  docker/
    app-stack/
```

## Example AWS VPC Module

```text
modules/aws/vpc/
  versions.tf
  variables.tf
  main.tf
  outputs.tf
```

### variables.tf

```hcl
variable "name" {
  type = string
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### main.tf

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}
```

### outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

---

# 10. Recommended Team Repository Layout

For teams, use two repositories.

## Repository 1: Infrastructure Modules

This repo stores shared templates.

```text
company-infra-modules/
  README.md
  modules/
    aws/
      vpc/
      ecs-cluster/
      ecs-service/
      eks-cluster/
      opensearch/
      msk-kafka/
      nifi-ecs/
      observability/
    azure/
      network/
      aks-cluster/
      app-service/
      event-hub/
      monitor/
    docker/
      kafka-stack/
      nifi-stack/
      observability-stack/
  examples/
    aws-dev-vpc/
    azure-dev-network/
    docker-local-kafka/
  tests/
  docs/
  versions.md
```

## Repository 2: Infrastructure Live

This repo stores real environment configuration.

```text
company-infra-live/
  root.hcl
  common.hcl
  aws/
    dev/
      us-east-1/
        env.hcl
        network/
          terragrunt.hcl
        ecs/
          terragrunt.hcl
        eks/
          terragrunt.hcl
        apps/
          kafka/
            terragrunt.hcl
          nifi/
            terragrunt.hcl
          opensearch/
            terragrunt.hcl
    prod/
      us-east-1/
        env.hcl
        network/
        eks/
        apps/
  azure/
    dev/
      eastus/
        env.hcl
        network/
        aks/
        apps/
  local/
    docker/
      kafka/
      nifi/
      observability/
```

## Why two repos?

| Repo | Purpose | Who changes it? |
|---|---|---|
| modules | Reusable templates | Platform team |
| live | Environment configuration | App/platform teams through review |

This allows a platform team to create safe templates while application teams configure simple inputs.

---

# 11. Terragrunt Basics

Terragrunt keeps environment configuration simple.

## root.hcl

```hcl
locals {
  company = "example-company"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "${local.company}-terraform-state"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF_PROVIDER
provider "aws" {
  region = var.aws_region
}
EOF_PROVIDER
}
```

## env.hcl

```hcl
locals {
  environment = "dev"
  aws_region  = "us-east-1"
  project     = "shared-platform"
  tags = {
    Environment = "dev"
    Project     = "shared-platform"
    ManagedBy   = "Terragrunt"
  }
}
```

## network/terragrunt.hcl

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "git::ssh://git@github.com/example/company-infra-modules.git//modules/aws/vpc?ref=v1.0.0"
}

inputs = {
  name                 = "${local.env.locals.project}-${local.env.locals.environment}-vpc"
  aws_region           = local.env.locals.aws_region
  cidr_block           = "10.10.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
  tags                 = local.env.locals.tags
}
```

## Run Terragrunt

From one folder:

```bash
terragrunt init
terragrunt plan
terragrunt apply
```

From an environment folder:

```bash
terragrunt run-all plan
terragrunt run-all apply
```

---

# 12. Terragrunt Live Infrastructure Layout

A clean Terragrunt layout looks like this:

```text
aws/dev/us-east-1/network/terragrunt.hcl
aws/dev/us-east-1/security/terragrunt.hcl
aws/dev/us-east-1/eks/terragrunt.hcl
aws/dev/us-east-1/apps/kafka/terragrunt.hcl
aws/dev/us-east-1/apps/nifi/terragrunt.hcl
aws/dev/us-east-1/apps/observability/terragrunt.hcl
```

Each layer has its own state file. That reduces risk.

## Dependency Example

The EKS layer needs VPC outputs.

```hcl
dependency "network" {
  config_path = "../network"
}

inputs = {
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
}
```

This means:

1. Create network first.
2. Read network outputs.
3. Use those outputs to create EKS.

---

# 13. AWS Foundation Example

## AWS Foundation Layers

Recommended order:

1. State bucket and locking
2. IAM baseline
3. Network/VPC
4. Security groups
5. KMS keys
6. ECR repositories
7. ECS or EKS
8. Data services
9. Observability
10. Applications

## AWS Provider

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
```

## ECR Module Example

```hcl
resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

---

# 14. AWS ECS Example

ECS is usually easier than Kubernetes for simple container workloads.

## When to use ECS

Use ECS when:

- You want managed container hosting.
- You do not need full Kubernetes complexity.
- You want fast AWS-native deployment.
- You use ALB, CloudWatch, IAM, and ECR.

## ECS Cluster Module

```hcl
resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```

## ECS Fargate Service Example

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }
}
```

## ECS Fault Tolerance

Use:

- At least two private subnets in different Availability Zones
- Application Load Balancer
- ECS service desired count of 2 or more
- Auto scaling based on CPU, memory, or request count
- CloudWatch alarms
- Health checks
- Immutable container images

---

# 15. AWS EKS and Kubernetes Example

EKS is AWS managed Kubernetes.

Use EKS when:

- You need Kubernetes APIs.
- You deploy many microservices.
- You use Helm charts.
- You need GitOps with Argo CD or Flux.
- You use service mesh, custom controllers, or complex workloads.

## Simple EKS Module Call

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    default = {
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
    }
  }
}
```

## Kubernetes Provider

After EKS exists, Kubernetes resources can be installed.

```hcl
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
```

## Namespace Example

```hcl
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}
```

## Helm Release Example

```hcl
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}
```

## EKS Production Add-ons

Recommended add-ons:

- VPC CNI
- CoreDNS
- kube-proxy
- AWS Load Balancer Controller
- ExternalDNS
- Cluster Autoscaler or Karpenter
- Metrics Server
- EBS CSI Driver
- EFS CSI Driver when shared storage is needed
- cert-manager
- External Secrets Operator
- Prometheus stack
- OpenTelemetry Collector
- Argo CD

---

# 16. Azure Foundation Example

## Azure Provider

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

## Resource Group

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location

  tags = var.tags
}
```

## Virtual Network

```hcl
resource "azurerm_virtual_network" "this" {
  name                = "${var.name}-vnet"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.private_subnet_cidr]
}
```

---

# 17. Azure AKS Example

AKS is Azure managed Kubernetes.

```hcl
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2s_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  tags = var.tags
}
```

## Azure Load Balancing Options

| Option | Use Case |
|---|---|
| Azure Load Balancer | Layer 4 TCP/UDP load balancing |
| Application Gateway | Layer 7 HTTP/S load balancing and WAF |
| Front Door | Global routing, CDN, edge WAF |
| NGINX Ingress | Kubernetes app ingress |
| AGIC | Application Gateway Ingress Controller for AKS |

---

# 18. Local Docker Platform Example

Use this for team demos, training, and local testing.

## Local Stack

```text
local-platform/
  main.tf
  variables.tf
  outputs.tf
```

## main.tf

```hcl
resource "docker_network" "platform" {
  name = "platform-net"
}

resource "docker_volume" "prometheus" {
  name = "prometheus-data"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "prom/prometheus:latest"

  networks_advanced {
    name = docker_network.platform.name
  }

  ports {
    internal = 9090
    external = 9090
  }
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = "grafana/grafana:latest"

  networks_advanced {
    name = docker_network.platform.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]
}
```

This is good for learning, but Docker Compose is often simpler for local-only stacks. Terraform is useful when you want one IaC workflow across Docker, cloud, and Kubernetes.

---

# 19. Kafka, ZooKeeper/KRaft, and NiFi Patterns

## Kafka Today

Older Kafka clusters used ZooKeeper. Newer Kafka designs often use KRaft mode instead of ZooKeeper. However, many organizations still run ZooKeeper-based Kafka, so teams should understand both.

## Local Kafka with Docker Compose

For local development, use Docker Compose instead of Terraform if the goal is fast developer startup.

```yaml
services:
  kafka:
    image: bitnami/kafka:latest
    ports:
      - "9092:9092"
    environment:
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9093
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - ALLOW_PLAINTEXT_LISTENER=yes
```

## Kafka on Kubernetes

For Kubernetes, prefer an operator or Helm chart.

Common options:

- Strimzi Kafka Operator
- Bitnami Kafka Helm chart
- Confluent for Kubernetes
- AWS MSK for managed Kafka
- Azure Event Hubs for Kafka-compatible ingestion

## Kafka Cluster Design

| Area | Recommendation |
|---|---|
| Brokers | Run 3 or more for high availability |
| Zones | Spread across multiple Availability Zones |
| Replication factor | Usually 3 for important topics |
| Min ISR | Usually 2 when replication factor is 3 |
| Storage | Use fast persistent disks |
| Monitoring | Track broker health, under-replicated partitions, consumer lag |
| Security | TLS, SASL, ACLs, secrets manager |

## NiFi Pattern

Apache NiFi is often used for data flow automation.

Use NiFi for:

- Reading files
- Pulling APIs
- Moving data to Kafka
- Transforming records
- Routing data based on rules
- Tracking data lineage

## NiFi on Kubernetes

Use Helm or a custom module that creates:

- Namespace
- StatefulSet or Helm release
- Persistent volumes
- Service
- Ingress
- Secrets
- ConfigMaps
- Registry integration

## NiFi Fault Tolerance

- Use NiFi cluster mode.
- Use persistent storage for flowfile, content, and provenance repositories.
- Use external ZooKeeper if required by your NiFi version/design.
- Use load-balanced connections where needed.
- Back up flow definitions and registry.
- Monitor queue sizes and back pressure.

---

# 20. Grafana, Prometheus, OpenTelemetry, and Logs

## Monitoring Layers

| Layer | Tool |
|---|---|
| Metrics | Prometheus |
| Dashboards | Grafana |
| Traces | OpenTelemetry Collector + Jaeger/Tempo |
| Logs | Loki, OpenSearch, CloudWatch, Azure Monitor |
| Alerts | Alertmanager, Grafana Alerting, CloudWatch Alarms, Azure Monitor Alerts |

## Kubernetes Prometheus Stack

```hcl
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [file("${path.module}/values/prometheus-values.yaml")]
}
```

## OpenTelemetry Collector

```hcl
resource "helm_release" "otel" {
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "observability"
  create_namespace = true
}
```

## Observability Template Inputs

```hcl
inputs = {
  enable_prometheus = true
  enable_grafana    = true
  enable_loki       = true
  enable_otel       = true
  retention_days    = 15
}
```

---

# 21. Load Balancing, Proxies, and Fault Tolerance

## Load Balancing Concepts

| Term | Meaning |
|---|---|
| Load balancer | Spreads traffic across healthy targets |
| Reverse proxy | Receives traffic and forwards to apps |
| Health check | Tests if service is alive |
| Failover | Moves traffic away from failed resource |
| Horizontal scaling | Add more instances/pods/tasks |
| Vertical scaling | Increase CPU/memory on existing nodes |
| Multi-AZ | Run across multiple datacenter zones |

## AWS Options

| Service | Use Case |
|---|---|
| ALB | HTTP/HTTPS apps |
| NLB | TCP/UDP or high-performance network traffic |
| Route 53 | DNS and health-check-based routing |
| CloudFront | CDN and edge caching |
| Global Accelerator | Global static IPs and routing |

## Azure Options

| Service | Use Case |
|---|---|
| Azure Load Balancer | TCP/UDP Layer 4 |
| Application Gateway | HTTP/S Layer 7 and WAF |
| Front Door | Global edge routing and WAF |
| Traffic Manager | DNS-based routing |

## Kubernetes Options

| Tool | Use Case |
|---|---|
| Service type LoadBalancer | Cloud load balancer per service |
| Ingress Controller | HTTP routing for many apps |
| NGINX Ingress | Common ingress proxy |
| AWS Load Balancer Controller | ALB/NLB integration |
| Istio/Linkerd | Service mesh |

## NGINX Reverse Proxy Example

```nginx
upstream app_backend {
  server app1:8080;
  server app2:8080;
}

server {
  listen 80;

  location / {
    proxy_pass http://app_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

---

# 22. OpenSearch Pattern

OpenSearch can support logs, search, analytics, and dashboards.

## AWS OpenSearch Terraform Pattern

```hcl
resource "aws_opensearch_domain" "this" {
  domain_name    = var.domain_name
  engine_version = "OpenSearch_2.17"

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }
}
```

## OpenSearch Production Notes

- Use dedicated master nodes for larger clusters.
- Use zone awareness.
- Use encryption at rest and in transit.
- Use fine-grained access control.
- Size storage carefully.
- Monitor JVM pressure, disk watermarks, shard count, and search latency.
- Use index lifecycle policies.

---

# 23. Ansible with Terraform and Terragrunt

Terraform creates infrastructure. Ansible configures operating systems and applications.

## Good Pattern

Use Terraform for:

- VPCs
- Subnets
- Load balancers
- IAM
- EC2 instances
- Security groups
- EKS/ECS/AKS

Use Ansible for:

- Installing packages
- Configuring Linux users
- Setting config files
- Installing agents
- Hardening OS settings
- Starting services

## Terraform Output Inventory

```hcl
output "ansible_inventory" {
  value = {
    web = aws_instance.web[*].private_ip
  }
}
```

## Generate Inventory

```bash
terraform output -json ansible_inventory > inventory.json
```

## Simple Ansible Playbook

```yaml
- name: Configure app servers
  hosts: web
  become: true
  tasks:
    - name: Install nginx
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

## Avoid This Pattern

Avoid using Terraform `remote-exec` for large software installation. It works for demos but becomes hard to maintain. Prefer Ansible, cloud-init, Packer, or container images.

---

# 24. CI/CD Pipeline Examples

## Pipeline Stages

1. Format check
2. Validate
3. Security scan
4. Plan
5. Manual approval
6. Apply

## GitLab CI Example

```yaml
stages:
  - validate
  - scan
  - plan
  - apply

variables:
  TF_IN_AUTOMATION: "true"

validate:
  stage: validate
  image: hashicorp/terraform:latest
  script:
    - terraform fmt -check -recursive
    - terraform init -backend=false
    - terraform validate

scan:
  stage: scan
  image: bridgecrew/checkov:latest
  script:
    - checkov -d .

plan_dev:
  stage: plan
  image: alpine/terragrunt:latest
  script:
    - cd aws/dev/us-east-1/network
    - terragrunt plan

apply_dev:
  stage: apply
  image: alpine/terragrunt:latest
  when: manual
  script:
    - cd aws/dev/us-east-1/network
    - terragrunt apply -auto-approve
```

## GitHub Actions Example

```yaml
name: Terraform Plan

on:
  pull_request:
  push:
    branches: [main]

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Install Terragrunt
        run: |
          curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.67.0/terragrunt_linux_amd64 -o terragrunt
          chmod +x terragrunt
          sudo mv terragrunt /usr/local/bin/terragrunt

      - name: Validate and Plan
        run: |
          cd aws/dev/us-east-1/network
          terragrunt init
          terragrunt validate
          terragrunt plan
```

---

# 25. Security Best Practices

## Core Rules

- Never commit secrets to Git.
- Use AWS IAM roles or Azure managed identities where possible.
- Use least privilege.
- Store state remotely and encrypted.
- Restrict state file access.
- Pin provider and module versions.
- Use code review for infrastructure changes.
- Require approval for production applies.
- Use MFA for human users.
- Use short-lived credentials for CI/CD.
- Scan code with Checkov, tfsec, or Terrascan.
- Use policy-as-code with OPA, Sentinel, or cloud policy tools.

## Secret Handling

Use:

- AWS Secrets Manager
- AWS SSM Parameter Store
- Azure Key Vault
- Kubernetes External Secrets Operator
- SOPS with age or KMS

Do not put secrets in:

- terraform.tfvars committed to Git
- outputs
- plain Kubernetes manifests
- local shell history

---

# 26. Testing and Validation

## Terraform Native Checks

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

## TFLint

```bash
tflint --init
tflint
```

## Checkov

```bash
checkov -d .
```

## Terratest

Terratest is a Go testing framework often used to deploy and test Terraform modules.

Example test idea:

1. Deploy VPC module.
2. Verify VPC exists.
3. Verify subnets exist.
4. Destroy module.

## Kitchen-Terraform

Another option for testing infrastructure modules.

## Pre-Commit Hooks

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.96.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

---

# 27. Cost Controls

## AWS Cost Controls

- Use AWS Budgets.
- Tag all resources.
- Use smaller instance types in dev.
- Stop unused EC2 instances.
- Use autoscaling.
- Use lifecycle rules for logs and S3.
- Avoid overprovisioned NAT gateways in dev.
- Use managed services carefully because they can be expensive.

## Azure Cost Controls

- Use Azure Budgets.
- Use tags.
- Use smaller SKUs in dev.
- Use auto-shutdown for VMs.
- Monitor Log Analytics ingestion.
- Review AKS node pool sizes.

## Terraform Cost Tools

- Infracost
- Cloud provider budget alerts
- Pull request cost comments

---

# 28. Team Template Governance

## Template Lifecycle

1. Platform team creates module.
2. Module is tested in examples.
3. Module is versioned with Git tags.
4. App teams consume the module through Terragrunt.
5. Changes go through pull requests.
6. Production uses pinned versions.
7. Old versions are deprecated with migration notes.

## Module Versioning

Use tags:

```text
v1.0.0
v1.1.0
v2.0.0
```

In Terragrunt:

```hcl
terraform {
  source = "git::ssh://git@github.com/example/company-infra-modules.git//modules/aws/vpc?ref=v1.1.0"
}
```

## Good Module Rules

- Keep modules small.
- Use clear input variables.
- Provide safe defaults.
- Output important IDs and names.
- Include README examples.
- Include diagrams for complex modules.
- Use tags everywhere.
- Avoid hardcoded account IDs, subscription IDs, regions, and secrets.

---

# 29. Beginner-to-Advanced Learning Path

## Level 1: Beginner

Learn:

- Providers
- Resources
- Variables
- Outputs
- `terraform init`, `plan`, `apply`, `destroy`

Practice:

- Local Docker nginx
- AWS S3 bucket
- Azure resource group

## Level 2: Basic Team Use

Learn:

- Remote state
- Modules
- Tags
- Environment tfvars

Practice:

- AWS VPC module
- Azure network module
- Docker app stack module

## Level 3: Terragrunt

Learn:

- root.hcl
- env.hcl
- remote_state
- include
- dependency
- run-all

Practice:

- dev and prod live folders
- shared VPC module
- shared ECS or AKS module

## Level 4: Kubernetes

Learn:

- EKS or AKS
- kubectl
- Helm
- namespaces
- ingress
- autoscaling

Practice:

- Deploy nginx ingress
- Deploy Prometheus stack
- Deploy sample app

## Level 5: Platform Engineering

Learn:

- module versioning
- policy as code
- CI/CD approvals
- security scanning
- drift detection
- cost controls
- observability

Practice:

- shared templates for all teams
- Kafka/NiFi/OpenSearch patterns
- full dev/test/prod promotion

---

# 30. Full Example Repository Skeleton

```text
company-infra-modules/
  README.md
  modules/
    aws/
      vpc/
        README.md
        versions.tf
        variables.tf
        main.tf
        outputs.tf
      ecs-cluster/
      ecs-service/
      eks-cluster/
      opensearch/
      observability-eks/
    azure/
      resource-group/
      network/
      aks-cluster/
      app-gateway/
      observability-aks/
    docker/
      nginx/
      kafka-kraft/
      nifi/
      prometheus-grafana/
  examples/
    aws-vpc-basic/
    aws-ecs-app/
    aws-eks-observability/
    azure-aks-basic/
    docker-local-platform/
  tests/
    aws-vpc-test/
  .github/
    workflows/
      validate.yml
  .pre-commit-config.yaml
```

```text
company-infra-live/
  README.md
  root.hcl
  common.hcl
  aws/
    dev/
      us-east-1/
        env.hcl
        network/terragrunt.hcl
        security/terragrunt.hcl
        ecs/terragrunt.hcl
        eks/terragrunt.hcl
        apps/
          kafka/terragrunt.hcl
          nifi/terragrunt.hcl
          opensearch/terragrunt.hcl
          observability/terragrunt.hcl
    prod/
      us-east-1/
        env.hcl
        network/terragrunt.hcl
        eks/terragrunt.hcl
        apps/
          kafka/terragrunt.hcl
  azure/
    dev/
      eastus/
        env.hcl
        network/terragrunt.hcl
        aks/terragrunt.hcl
        apps/
          observability/terragrunt.hcl
  local/
    docker/
      env.hcl
      kafka/terragrunt.hcl
      nifi/terragrunt.hcl
      observability/terragrunt.hcl
```

---

# 31. Common Troubleshooting

## Problem: Terraform says resource already exists

Cause: The resource exists but is not in state.

Fix options:

- Import it with `terraform import`.
- Rename resource.
- Delete old resource if safe.

## Problem: State lock is stuck

Cause: Previous run failed or was interrupted.

Fix:

- Confirm no one else is running Terraform.
- Use force unlock only when safe.

```bash
terraform force-unlock LOCK_ID
```

## Problem: Terragrunt cannot find env.hcl

Cause: Folder structure is wrong or `find_in_parent_folders` cannot locate file.

Fix:

- Check folder path.
- Confirm env.hcl exists above the current folder.

## Problem: Kubernetes provider fails after creating EKS

Cause: Terraform tries to use Kubernetes provider before cluster is ready.

Fix:

- Split EKS cluster and Kubernetes add-ons into separate state layers.
- Use Terragrunt dependency outputs.
- Apply cluster first, then add-ons.

## Problem: Secrets show in state

Cause: Terraform stores resource values in state.

Fix:

- Do not output secrets.
- Mark sensitive variables and outputs.
- Restrict backend access.
- Prefer references to secret managers rather than raw secret values.

---

# 32. Official References

- Terraform Documentation: https://developer.hashicorp.com/terraform/docs
- Terraform Providers: https://registry.terraform.io/browse/providers
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform AzureRM Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Terraform S3 Backend: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform AzureRM Backend: https://developer.hashicorp.com/terraform/language/backend/azurerm
- Terraform State: https://developer.hashicorp.com/terraform/language/state
- Terragrunt Documentation: https://terragrunt.gruntwork.io/docs/
- Terragrunt Config Blocks: https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/
- AWS EKS Terraform Tutorial: https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks
- Terraform AWS EKS Module: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- Kubernetes Documentation: https://kubernetes.io/docs/
- Helm Documentation: https://helm.sh/docs/
- Ansible Documentation: https://docs.ansible.com/
- Prometheus Documentation: https://prometheus.io/docs/
- Grafana Documentation: https://grafana.com/docs/
- OpenTelemetry Documentation: https://opentelemetry.io/docs/
- Apache Kafka Documentation: https://kafka.apache.org/documentation/
- Apache NiFi Documentation: https://nifi.apache.org/docs.html
- OpenSearch Documentation: https://opensearch.org/docs/

---

# Final Recommendation

For a real team, start with this order:

1. Build shared modules repo.
2. Build live Terragrunt repo.
3. Create AWS and Azure remote state.
4. Create network modules first.
5. Add ECS/EKS/AKS modules.
6. Add observability modules.
7. Add Kafka/NiFi/OpenSearch patterns.
8. Add CI/CD with plan on pull request and manual apply.
9. Add security scans and cost checks.
10. Version every module and teach teams to configure only simple inputs.

The best team setup is not one giant Terraform file. The best setup is a small set of safe, tested modules combined with simple Terragrunt environment folders.
