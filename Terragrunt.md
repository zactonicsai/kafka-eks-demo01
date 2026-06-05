# The Complete Terraform & Terragrunt Tutorial (Annotated Edition)

> A comprehensive, beginner-to-advanced guide with reference links, line-by-line code annotations, and step-by-step walkthroughs.
>
> Covers: Terraform · Terragrunt · OpenTofu · AWS · Azure · local Docker · Kubernetes (EKS/AKS) · ECS · Ansible · Kafka · NiFi · OpenSearch · Prometheus · Grafana · OpenTelemetry · load balancing · fault tolerance · team collaboration.

---

## How to Read This Tutorial

This document is organized **bottom-up**: each section builds on the previous one. If you're a complete beginner, read it linearly. If you're experienced, use the table of contents.

Throughout the document you'll see these callouts:

> **📚 Background:** deeper context — *why* something works the way it does, not just *how*.

> **🔗 References:** links to official documentation and authoritative sources.

> **⚠️ Gotcha:** common mistakes and how to avoid them.

> **✅ Step-by-step:** numbered walkthrough of an example from clean directory to result.

Code blocks marked `# 1` `# 2` `# 3` etc. have a line-by-line explanation immediately after them.

---

## Table of Contents

1. [Introduction & Background](#1-introduction--background)
2. [Core Concepts](#2-core-concepts)
3. [Installation & Setup](#3-installation--setup)
4. [Terraform Fundamentals](#4-terraform-fundamentals)
5. [State Management — Deep Dive](#5-state-management--deep-dive)
6. [Variables, Outputs, Locals, Conditionals & Error Handling](#6-variables-outputs-and-locals)
7. [Modules and Reusability](#7-modules-and-reusability)
8. [Your First Project — Local Docker](#8-your-first-project--local-docker)
9. [AWS Basics — Annotated](#9-aws-basics--annotated)
10. [Azure Basics — Annotated](#10-azure-basics--annotated)
11. [Terragrunt — The Why and the How](#11-terragrunt--the-why-and-the-how)
12. [Layered Architecture for Teams](#12-layered-architecture-for-teams)
13. [Shared Module Patterns](#13-shared-module-patterns)
14. [Kubernetes — EKS, AKS, kubectl/helm providers](#14-kubernetes-with-terraform)
15. [AWS ECS](#15-aws-ecs)
16. [Ansible Integration](#16-ansible-integration)
17. [Complex Workloads — Kafka, NiFi, OpenSearch](#17-complex-workloads)
18. [Observability — Prometheus, Grafana, OpenTelemetry](#18-observability)
19. [Load Balancing & Fault Tolerance](#19-load-balancing-and-fault-tolerance)
20. [CI/CD & Team Workflows](#20-cicd-and-team-workflows)
21. [Troubleshooting & Best Practices](#21-troubleshooting--best-practices)
22. [Error Handling & Conditional Logic](#22-error-handling-and-conditional-logic)
23. [Appendices](#23-appendices)

---

# 1. Introduction & Background

## 1.1 What is Infrastructure as Code (IaC)?

Before IaC, managing servers and cloud resources meant one of two things: clicking buttons in a web console, or running shell scripts that called the cloud's CLI. Both approaches share fundamental problems:

1. **No reliable record of what exists.** If three engineers each click around in the AWS console, only a careful audit reveals what's actually deployed. The console *is* the source of truth, and it's not version-controlled.
2. **Manual changes drift.** A quick fix made at 2 AM during an incident never gets back-ported into the "official" config — assuming there is one.
3. **No reproducibility.** Setting up a staging environment that exactly mirrors production is a multi-day project of squinting at two browser tabs.
4. **No peer review.** Changes happen invisibly; mistakes happen silently.

**Infrastructure as Code (IaC)** treats every piece of infrastructure (VMs, networks, DNS records, load balancers, Kubernetes clusters, databases, IAM policies, monitoring dashboards…) as files in a git repository. Those files declare *the desired state of the world*, and a tool (Terraform, in our case) figures out how to make reality match.

The benefits chain together:

| Capability                | How IaC delivers it                                    |
| ------------------------- | ------------------------------------------------------ |
| **Reproducibility**       | The same code applied twice produces the same result   |
| **Versioning**            | Git history shows what changed, when, by whom, and why |
| **Code review**           | Pull requests apply to infra the same way as app code  |
| **Drift detection**       | Compare declared state vs. real state on a schedule    |
| **Composability**         | Small modules combine into systems                     |
| **Disaster recovery**     | Spin up your platform in another region from scratch   |
| **Auditability**          | Compliance asks "what changed?"; git answers           |

> **🔗 References:**
> - HashiCorp's *"What is Infrastructure as Code?"* — https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code
> - ThoughtWorks Tech Radar on IaC — https://www.thoughtworks.com/radar/techniques/infrastructure-as-code
> - Google's *Site Reliability Engineering* book, chapter on configuration management — https://sre.google/sre-book/

## 1.2 Why Terraform?

[Terraform](https://www.terraform.io/), created by HashiCorp and open-sourced in 2014 (now part of IBM after a 2024 acquisition), became the de-facto industry standard for multi-cloud IaC. The reasons it won:

- **Declarative.** You describe the *end state* you want; Terraform computes the difference between current reality and your declaration, then makes the API calls to close the gap. You don't write "create this VM, then attach this disk, then…" — you write "this VM should exist with this disk attached" and Terraform figures out the sequencing.
- **Provider-agnostic.** The [Terraform Registry](https://registry.terraform.io/) hosts over 3,000 providers covering AWS, Azure, GCP, Kubernetes, GitHub, Datadog, MongoDB Atlas, Cloudflare, Auth0, Stripe — essentially every modern API.
- **Stateful.** Terraform keeps a *state file* mapping each resource you declared to its real-world identifier (e.g., `aws_s3_bucket.logs` ↔ `arn:aws:s3:::my-team-logs-12345`). This is what lets it tell the difference between "create this new resource" and "update the existing one."
- **HCL (HashiCorp Configuration Language).** Readable, JSON-compatible, with first-class loops, conditionals, expressions, and module composition.

### Terraform vs. its alternatives

| Tool                              | Best for                                            | Notable limitation                                 |
| --------------------------------- | --------------------------------------------------- | -------------------------------------------------- |
| **Terraform**                     | Multi-cloud, huge ecosystem, mature                 | State management complexity                        |
| **[OpenTofu](https://opentofu.org/)** | Same as Terraform but fully open-source         | Younger; community-led governance                  |
| **[AWS CloudFormation](https://aws.amazon.com/cloudformation/)** | Deepest AWS integration              | AWS-only; YAML/JSON only; slower feature parity    |
| **[AWS CDK](https://aws.amazon.com/cdk/)** | Real programming languages over CloudFormation | Still AWS-centric; generates CloudFormation under the hood |
| **[Pulumi](https://www.pulumi.com/)** | Real languages (TypeScript, Python, Go, …)      | Smaller ecosystem; IDE-dependent ergonomics        |
| **[Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)** | Native Azure DSL    | Azure-only                                         |
| **[Crossplane](https://www.crossplane.io/)** | IaC inside Kubernetes (provisioning via CRDs) | Requires K8s; different mental model               |
| **[Ansible](https://www.ansible.com/)** | Agentless config management + orchestration   | Imperative for IaC; weaker drift model             |

### The OpenTofu fork — important to know

In August 2023, HashiCorp changed Terraform's license from MPL 2.0 (free open source) to the **BUSL** (Business Source License), which restricts competitive commercial use. The Linux Foundation accepted a fork named **[OpenTofu](https://opentofu.org/)**, which is binary-drop-in compatible with Terraform 1.5 and continues under MPL 2.0.

For practical purposes:

- **Everything in this tutorial works with both.** HCL syntax, providers, modules — all shared.
- **Choose OpenTofu** for new projects if you want a fully open-source license and Linux Foundation governance.
- **Choose Terraform** if you're already invested in the HashiCorp ecosystem (Terraform Cloud / HCP, Sentinel policies, Vault integration).
- The community is gravitating toward `tofu` for tooling examples; the syntax is identical so we'll use `terraform` throughout for familiarity.

> **🔗 References:**
> - Terraform docs — https://developer.hashicorp.com/terraform/docs
> - OpenTofu docs — https://opentofu.org/docs/
> - The BSL relicense announcement — https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license
> - OpenTofu's announcement — https://opentofu.org/blog/opentofu-announces-fork-of-terraform/
> - HCL language spec — https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md

## 1.3 Why Terragrunt?

Terraform alone works wonderfully for a single project. But as soon as you have multiple environments (dev/staging/prod), multiple regions, and multiple teams, repetitive boilerplate explodes:

- Every `terraform` directory needs a `backend` block configuring where its state lives.
- Every directory needs `provider` blocks.
- Common variables (account IDs, regions, tags) get copy-pasted dozens of times.
- Cross-stack dependencies ("the EKS module needs the VPC ID from the network module") have to be wired by hand.
- Applying 30 components in the right order from one command? Not built in.

**[Terragrunt](https://terragrunt.gruntwork.io/)**, created by [Gruntwork](https://gruntwork.io/), is a thin wrapper around Terraform that solves these. It is:

1. **A DRY (Don't Repeat Yourself) layer** for backends, providers, and common inputs — defined once, inherited everywhere.
2. **A dependency graph engine** between Terraform modules — automatically passes outputs of one as inputs to another.
3. **A runner** that applies many modules in dependency order with one command.

The mental model:

```
Application development:   pyproject.toml / package.json  →  pip / npm
Infrastructure development: terragrunt.hcl                →  terraform
```

Terragrunt **does not replace** Terraform. Under the hood it generates the boilerplate files (`backend.tf`, `provider.tf`) on the fly and calls `terraform` with the right arguments.

> **🔗 References:**
> - Terragrunt official docs — https://terragrunt.gruntwork.io/docs/
> - Gruntwork's "How to use Terragrunt" guide — https://terragrunt.gruntwork.io/docs/getting-started/quick-start/
> - The book *Terraform: Up & Running* by Yevgeniy Brikman covers Terragrunt extensively — https://www.terraformupandrunning.com/

## 1.4 The mental model for this entire tutorial

```
                  ┌─────────────────────────────────────┐
                  │  Your team's git repo               │
                  │                                     │
                  │  ┌──────────────────────────────┐   │
                  │  │ live/   (per-env config)     │   │ ◄── Terragrunt
                  │  │   prod/eu-west-1/eks/        │   │     (small files,
                  │  │   staging/eu-west-1/eks/     │   │      inherit a lot)
                  │  └──────────────┬───────────────┘   │
                  │                 │ inputs            │
                  │                 ▼                   │
                  │  ┌──────────────────────────────┐   │
                  │  │ modules/  (reusable, tagged) │   │ ◄── Terraform
                  │  │   eks/                       │   │     (versioned
                  │  │   vpc/                       │   │      libraries)
                  │  │   rds/                       │   │
                  │  └──────────────┬───────────────┘   │
                  └─────────────────┼───────────────────┘
                                    │  provider plugins
                                    ▼
                  ┌─────────────────────────────────────┐
                  │ AWS / Azure / GCP / Kubernetes / …  │
                  └─────────────────────────────────────┘
```

Read that diagram bottom-up:

1. The world has many APIs (AWS, Azure, K8s, …).
2. Terraform **providers** know how to talk to those APIs.
3. Your **modules** wrap providers into reusable units (a "VPC", an "EKS cluster").
4. Your **live config** instantiates those modules per environment.
5. **Terragrunt** keeps the live config DRY and wires modules together.

The rest of the tutorial walks bottom-up: Terraform basics → modules → Docker example → cloud examples → Terragrunt → layered team architecture → complex workloads.

---

# 2. Core Concepts

Before installing anything, internalize these terms — they appear in every Terraform file you'll ever read.

## 2.1 Providers

> **📚 Background:** A *provider* is the plugin that translates Terraform's declarative resource blocks into API calls. Without providers, Terraform is just a parser — it doesn't know what AWS or Kubernetes is. Providers are independently versioned, downloaded at `init` time, and pinned in your lock file.

```hcl
# 1
terraform {
  # 2
  required_providers {
    # 3
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# 4
provider "aws" {
  region = "eu-west-1"
}
```

**Line-by-line:**

- **`# 1`** — The `terraform { }` block configures Terraform itself (not any specific cloud). It holds version constraints, required providers, and the backend.
- **`# 2`** — `required_providers` lists every provider this module uses, with a source address and version constraint.
- **`# 3`** — `aws = { ... }` gives the provider a **local name** ("aws") that you'll reference elsewhere. `source = "hashicorp/aws"` is the registry address ([registry.terraform.io/providers/hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/latest)). `version = "~> 5.60"` is a *pessimistic constraint*: allow `5.60.x` patch releases but not `5.61.0` or `6.x`.
- **`# 4`** — `provider "aws" { }` actually instantiates the provider with configuration. `region = "eu-west-1"` tells it which AWS region to talk to. You can also set `profile`, `assume_role`, `default_tags`, etc.

> **⚠️ Gotcha:** A bare `provider` block with no `required_providers` works but is fragile — Terraform will pull "the latest" of whatever it can find, which can change between `terraform init` runs. **Always pin** with `required_providers`.

> **🔗 References:**
> - Provider configuration — https://developer.hashicorp.com/terraform/language/providers
> - Provider version constraints — https://developer.hashicorp.com/terraform/language/expressions/version-constraints
> - The full provider registry — https://registry.terraform.io/browse/providers

## 2.2 Resources

> **📚 Background:** A *resource* is a single piece of infrastructure that Terraform manages — one S3 bucket, one VM, one DNS record. Resources have a **type** (defined by the provider) and a **local name** (your choice). Together they form a globally unique address inside your Terraform configuration.

```hcl
# 1
resource "aws_s3_bucket" "logs" {
  # 2
  bucket = "my-team-logs-12345"

  # 3
  tags = {
    Environment = "prod"
    Owner       = "platform-team"
  }
}
```

**Line-by-line:**

- **`# 1`** — `resource "aws_s3_bucket" "logs"` declares a resource. The first label is the **type** (`aws_s3_bucket`, provided by the AWS provider). The second is your local **name** (`logs`). You'll reference this resource elsewhere as `aws_s3_bucket.logs`.
- **`# 2`** — `bucket = "my-team-logs-12345"` is an **argument** specific to `aws_s3_bucket`. S3 bucket names are globally unique across all AWS accounts — pick something distinctive.
- **`# 3`** — `tags` is a map of arbitrary key-value pairs AWS attaches to the bucket. Tags are how you organize costs, ownership, and access policies.

Accessing attributes elsewhere:

```hcl
output "log_bucket_arn" {
  value = aws_s3_bucket.logs.arn  # the ARN is computed after creation
}
```

> **🔗 References:**
> - AWS provider — `aws_s3_bucket` documentation — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
> - The Resources language reference — https://developer.hashicorp.com/terraform/language/resources

## 2.3 Data sources

> **📚 Background:** A *data source* reads existing infrastructure that's *not* managed by this Terraform configuration. It's how you reference a resource that someone else (or another Terraform stack) created. Data sources are read-only — they make API queries during `plan`/`apply` but never mutate anything.

```hcl
# 1
data "aws_vpc" "default" {
  default = true
}

# 2
data "aws_subnets" "in_default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 3
output "default_vpc_cidr" {
  value = data.aws_vpc.default.cidr_block
}
```

**Line-by-line:**

- **`# 1`** — Reads the default VPC. `default = true` is a filter argument: "find the VPC marked as default in this account/region." The result is accessed as `data.aws_vpc.default.<attribute>`.
- **`# 2`** — Reads all subnets *inside* that VPC. Notice we reference the data source's `id` attribute. Data sources can depend on each other just like resources.
- **`# 3`** — Exposes the VPC's CIDR block as an output (we cover outputs in §6).

**When to use data sources:**

| Use case                                          | Example                                                      |
| ------------------------------------------------- | ------------------------------------------------------------ |
| Reference resources from another Terraform stack  | Read `aws_vpc.main.id` produced by the network stack         |
| Reference manually-created resources              | Reference an ACM certificate created via the AWS console     |
| Look up provider-managed data                     | Get the latest Amazon Linux AMI ID                           |
| Read existing IAM, KMS, Route 53 hosted zones     | Anything shared across stacks                                |

> **🔗 References:**
> - The Data Sources language reference — https://developer.hashicorp.com/terraform/language/data-sources
> - `aws_vpc` data source docs — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc

## 2.4 State

> **📚 Background:** The state file (`terraform.tfstate`) is a JSON document that maps every `resource` block in your configuration to the real-world object it represents. When you run `terraform plan`, Terraform:
>
> 1. Reads your current `.tf` files (the *desired state*).
> 2. Reads the state file (the *previous known state*).
> 3. Optionally refreshes by querying the provider (the *actual real-world state*).
> 4. Computes the diff between desired and actual.
> 5. Generates a plan to close the gap.
>
> Without state, Terraform would have no idea which AWS bucket corresponds to `aws_s3_bucket.logs` — it would try to create a new one every time, fail because the name is taken, and panic.

State **must be stored remotely with locking** for any team work. We cover that in §5.

> **⚠️ Gotcha:** State files often contain **secrets**. Generated passwords (`random_password`), RDS master passwords, anything `sensitive = true` — all readable in plain text inside the state JSON. Treat state as classified.

## 2.5 Plan and apply

Two of the three commands you'll run every day:

| Command                  | What it does                                                                       |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `terraform plan`         | Computes what would change. Read-only. Shows a colored diff. **Always read this.** |
| `terraform apply`        | Executes the plan after a y/n prompt.                                              |
| `terraform apply -auto-approve` | Skip the prompt — only in CI.                                              |
| `terraform destroy`      | Generates a plan to delete *everything* in this state, then applies it.            |

A plan looks like:

```
Terraform will perform the following actions:

  # aws_s3_bucket.logs will be created
  + resource "aws_s3_bucket" "logs" {
      + acceleration_status         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "my-team-logs-12345"
      + force_destroy               = false
      + id                          = (known after apply)
      + ...
      + tags                        = {
          + "Environment" = "prod"
          + "Owner"       = "platform-team"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Read every `+ create`, `~ update`, and especially `- destroy` line. The `- destroy` line on a production database is how you lose your job.

## 2.6 Modules

> **📚 Background:** A *module* is a folder of `.tf` files that gets reused. The folder you `terraform apply` from is called the **root module**. When that root module references another folder via a `module { source = ... }` block, the referenced folder is a **child module**.
>
> Modules are how you build abstraction. A single `module "vpc"` call replaces ~50 hand-written resources. Good modules have clear inputs (variables), useful outputs, and a single purpose.

```hcl
# 1
module "vpc" {
  # 2
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  # 3
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}
```

**Line-by-line:**

- **`# 1`** — `module "vpc"` instantiates a child module. `"vpc"` is the local name; you'll reference its outputs as `module.vpc.vpc_id`.
- **`# 2`** — `source` tells Terraform *where to find the module's code*. Here it's a path on the [Terraform Registry](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest). It could also be a relative path (`./modules/vpc`), a git URL (`git::https://github.com/foo/bar.git//vpc?ref=v1.0`), an S3 URL, or even a local filesystem absolute path. `version = "5.13.0"` pins the exact version — strongly recommended for stability.
- **`# 3`** — Everything else is an **input variable** the module accepts. The module's documentation lists every input.

> **🔗 References:**
> - Modules language reference — https://developer.hashicorp.com/terraform/language/modules
> - The community AWS modules (gold standard for module design) — https://github.com/terraform-aws-modules
> - The `terraform-aws-modules/vpc` reference — https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

## 2.7 Workspaces (and why you should rarely use them)

> **📚 Background:** Terraform's "workspaces" feature lets you have multiple state files for the same code. The default workspace is called `default`; you can create others with `terraform workspace new dev`. Each workspace gets its own state. The same code applied in different workspaces produces independent infrastructure.
>
> *This sounds great for environments. It isn't.*

The community consensus (and HashiCorp's later guidance) is that **workspaces should not be used for dev/staging/prod**, for these reasons:

1. **They hide which environment you're in.** Running `terraform apply` doesn't show whether you're in `dev` or `prod` workspace unless you check first. People have destroyed production this way.
2. **They encourage shared code paths between environments that should diverge.** Prod often legitimately needs different settings (multi-AZ, larger instances, longer backups) — `if workspace == "prod"` conditionals everywhere becomes the result.
3. **Backend configuration is shared.** All workspaces use the same backend, just different state files — you can't put prod state in a different account from dev state.

**The recommended pattern instead:** use **separate directories** per environment with **separate backends**, glued together by Terragrunt. We cover this thoroughly in §12.

Workspaces are fine for **short-lived feature branches** within the same environment (testing a refactor in an ephemeral state alongside the main one).

> **🔗 References:**
> - HashiCorp's workspaces documentation (with the now-explicit warning) — https://developer.hashicorp.com/terraform/language/state/workspaces
> - Gruntwork's article on why not to use workspaces for envs — https://blog.gruntwork.io/how-to-manage-multiple-environments-with-terraform-using-terragrunt-2c3e9b4b8b

---

# 3. Installation & Setup

This section assumes a Unix-like environment (macOS or Linux). Windows users: most things work in WSL2 identically; native PowerShell installs work but are less common in production setups.

## 3.1 Install Terraform

> **📚 Background:** Different projects pin to different Terraform versions, just like Node.js or Python projects pin language versions. Always use a **version manager** like `tfenv` so you can switch versions per directory.

### macOS (Homebrew)

```bash
# Install tfenv (manages multiple Terraform versions)
brew install tfenv

# Install a specific version
tfenv install 1.9.5

# Set it as the default
tfenv use 1.9.5

# In any project, pin its version
echo "1.9.5" > .terraform-version
git add .terraform-version
```

When you `cd` into a directory with a `.terraform-version` file, `tfenv` automatically uses that version.

For OpenTofu specifically:

```bash
brew install opentofu          # plain install
# or use tofuenv (the OpenTofu equivalent of tfenv)
brew install tofuenv
tofuenv install 1.8.0
tofuenv use 1.8.0
```

### Linux (apt — Debian/Ubuntu)

```bash
# 1
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 2
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

# 3
sudo apt update && sudo apt install terraform
```

**Line-by-line:**

- **`# 1`** — Download HashiCorp's GPG signing key, dearmor it (convert ASCII-armor → binary), and save to the trusted keyrings directory. This is how `apt` will verify that packages from this repo were really signed by HashiCorp.
- **`# 2`** — Add the HashiCorp apt repo to your sources list. `lsb_release -cs` produces the codename of your distro (e.g., `noble` for Ubuntu 24.04). The `signed-by=` tells apt which key to use.
- **`# 3`** — Refresh the package index and install.

### Windows (Chocolatey)

```powershell
choco install terraform
```

### Verify the install

```bash
terraform -version
# Terraform v1.9.5
# on linux_amd64
```

> **🔗 References:**
> - Official Terraform downloads — https://developer.hashicorp.com/terraform/install
> - `tfenv` GitHub — https://github.com/tfutils/tfenv
> - `tofuenv` GitHub — https://github.com/tofuutils/tofuenv
> - OpenTofu install — https://opentofu.org/docs/intro/install/

## 3.2 Install Terragrunt

```bash
# macOS
brew install terragrunt

# Linux: download the binary directly
TG_VERSION="0.67.0"
wget "https://github.com/gruntwork-io/terragrunt/releases/download/v${TG_VERSION}/terragrunt_linux_amd64"
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

terragrunt -v
```

Like `tfenv`, there's [`tgenv`](https://github.com/cunymatthieu/tgenv) for multiple Terragrunt versions.

> **🔗 References:**
> - Terragrunt releases — https://github.com/gruntwork-io/terragrunt/releases
> - Installation guide — https://terragrunt.gruntwork.io/docs/getting-started/install/

## 3.3 Cloud CLIs

### AWS CLI

```bash
# Install
brew install awscli                          # macOS
sudo apt install awscli                      # Debian/Ubuntu
# or:  pip install awscli --user

# Configure
aws configure                                # interactive: keys + region

# Verify — should show your IAM user/role
aws sts get-caller-identity
# {
#   "UserId": "AIDAEXAMPLE",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/jane.doe"
# }
```

#### Production-grade AWS auth: SSO + role assumption

> **⚠️ Gotcha:** Don't use long-lived access keys for daily work. They get committed to repos, leaked in screenshots, and outlive their owners. **Use AWS Identity Center (SSO)** for humans and **OIDC federation** for CI.

`~/.aws/config`:

```ini
# 1
[sso-session my-org]
sso_start_url      = https://my-org.awsapps.com/start
sso_region         = eu-west-1
sso_registration_scopes = sso:account:access

# 2
[profile prod-admin]
sso_session    = my-org
sso_account_id = 111122223333
sso_role_name  = AdministratorAccess
region         = eu-west-1

# 3
[profile prod-tf]
sso_session    = my-org
sso_account_id = 111122223333
sso_role_name  = TerraformExecutionRole
region         = eu-west-1
```

**Line-by-line:**

- **`# 1`** — Defines an SSO session shared by multiple profiles. `sso_start_url` is your company's AWS Identity Center portal. You'll log in via browser once per ~8 hours.
- **`# 2`** — A profile for human admin access to the prod account.
- **`# 3`** — A separate profile assuming a *Terraform-specific role*. This role has only the IAM permissions Terraform needs, no more. Use this profile to run `terraform apply`.

Login flow:

```bash
aws sso login --sso-session my-org             # browser opens, you log in
export AWS_PROFILE=prod-tf                     # tell SDKs which profile to use
aws sts get-caller-identity                    # verify the role
terraform apply
```

> **🔗 References:**
> - AWS CLI configure docs — https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
> - AWS IAM Identity Center (SSO) — https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html
> - AWS provider authentication — https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration

### Azure CLI

```bash
brew install azure-cli                       # macOS
# Debian/Ubuntu: see https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux

az login                                     # browser-based interactive login
az account list -o table                     # list subscriptions
az account set --subscription "<sub-id>"     # pick one
az account show                              # confirm
```

For CI, use a **service principal** or — preferred — **OIDC federation** (no static secrets).

> **🔗 References:**
> - Azure CLI install — https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
> - AzureRM provider auth options — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli

### Docker

```bash
# macOS — install Docker Desktop
brew install --cask docker

# Linux — install Docker Engine
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER                # add yourself to docker group
newgrp docker                                # apply without re-login

# Verify
docker run --rm hello-world
```

### kubectl and helm (for Kubernetes sections)

```bash
brew install kubectl helm
kubectl version --client
helm version
```

> **🔗 References:**
> - Docker Desktop — https://www.docker.com/products/docker-desktop/
> - kubectl install — https://kubernetes.io/docs/tasks/tools/install-kubectl/
> - Helm install — https://helm.sh/docs/intro/install/

## 3.4 Editor setup

**VS Code** — install the [HashiCorp Terraform extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform). You get syntax highlighting, autocomplete, format-on-save, validation, and documentation hovers.

Recommended VS Code `settings.json` additions:

```jsonc
{
  // Format Terraform on save
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  },
  // Validate on save (slower but catches errors immediately)
  "terraform.validation.enableEnhancedValidation": true
}
```

**JetBrains IDEs (IntelliJ, GoLand, PyCharm)** — the [HashiCorp Terraform / HCL plugin](https://plugins.jetbrains.com/plugin/7808-hashicorp-terraform--hcl-language-support) is bundled.

**Vim/Neovim** — `tree-sitter-hcl` and `terraform-ls` via LSP. Install via your favorite plugin manager.

## 3.5 Project bootstrap checklist

For every new Terraform/Terragrunt repo, create these files first:

```
.
├── .gitignore                  # see below
├── .terraform-version          # e.g.  "1.9.5"
├── .terragrunt-version         # e.g.  "0.67.0"
├── .pre-commit-config.yaml     # auto-format and lint on commit (§13.5)
├── README.md                   # what is this repo, how to use it
├── modules/                    # reusable Terraform modules
└── live/                       # actual deployed configurations
```

A solid `.gitignore`:

```gitignore
# Terraform state should NEVER be in git
*.tfstate
*.tfstate.*
*.tfstate.backup

# Terraform plan files — they can contain secrets in clear
*.tfplan
plan.out

# Local Terraform working dir — provider binaries, downloaded modules
.terraform/

# Sensitive variable files — commit example.tfvars only, never the real one
*.tfvars
*.tfvars.json
!example.tfvars
!example.tfvars.json

# Crash logs
crash.log
crash.*.log

# Terragrunt working directory
.terragrunt-cache/

# Override files — local-only experiments
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Environment files
.env
.env.local
```

> **✅ One thing you SHOULD commit:** the **`.terraform.lock.hcl`** file in each Terraform directory. We cover this in §4.6 — it pins exact provider versions and checksums for supply-chain security.

---

# 4. Terraform Fundamentals

## 4.1 HCL syntax — the building blocks

> **📚 Background:** HCL (HashiCorp Configuration Language) is a config language designed to be both human-friendly and machine-friendly. Every HCL file can be losslessly converted to JSON and vice versa. The HCL parser knows about *blocks* (with curly braces and labels), *arguments* (key-value pairs), and *expressions* (the right-hand sides of arguments).

The fundamental syntactic unit is a **block**:

```hcl
# block_type "label1" "label2" {  ...arguments... }
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name = "web-server"
  }
}
```

- `resource` is the **block type**.
- `"aws_instance"` and `"web"` are **labels** (different block types take different numbers of labels — `resource` takes two, `provider` takes one).
- Inside the braces are **arguments** (`ami = "..."`) and possibly nested blocks (`tags = { ... }` is technically an argument with a map value, but you'll also see real nested blocks).

### Types you'll use constantly

```hcl
# Primitive types
name      = "alice"                   # string
count_arg = 3                         # number
enabled   = true                      # bool
nothing   = null                      # the absence of a value

# Lists / tuples (ordered, indexed)
zones = ["a", "b", "c"]
mixed = ["one", 2, true]              # tuples allow mixed types; lists don't

# Maps / objects (key-value)
tags = { env = "prod", team = "platform" }   # map (homogeneous values)

# Objects are typed maps where each key has its own type
endpoint = {
  host = "db.example.com"             # string
  port = 5432                         # number
  tls  = true                         # bool
}

# Sets (unordered, unique)
allowed_users = toset(["alice", "bob", "alice"])  # → ["alice", "bob"]

# Heredoc strings (multi-line)
policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "*" }
    ]
  }
EOT
```

The leading hyphen in `<<-EOT` means "strip leading indentation" — handy for keeping indented code readable in source while not introducing indentation in the resulting string.

> **🔗 References:**
> - HCL syntax spec — https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md
> - Terraform language reference — https://developer.hashicorp.com/terraform/language/syntax/configuration
> - Type system — https://developer.hashicorp.com/terraform/language/expressions/types

### Expressions

Any value on the right of an `=` is an expression. Expressions can reference other resources, do arithmetic, call functions, use conditionals, and iterate:

```hcl
# Reference another resource's attribute
vpc_id = aws_vpc.main.id

# Arithmetic
desired = var.base_count + 2

# Function call
bucket_name = lower("MyBucket-${var.env}")

# Conditional (ternary)
instance_type = var.environment == "prod" ? "m6i.large" : "t3.small"

# List comprehension (for-expression)
public_subnet_ids = [for s in aws_subnet.public : s.id]

# Map comprehension
subnet_by_az = { for s in aws_subnet.public : s.availability_zone => s.id }

# Splat expression (shorthand for one common pattern)
all_subnet_ids = aws_subnet.public[*].id     # equivalent to the for-expression above
```

> **🔗 References:**
> - Expressions reference — https://developer.hashicorp.com/terraform/language/expressions
> - All built-in functions — https://developer.hashicorp.com/terraform/language/functions

## 4.2 Providers in detail

A well-structured project pulls all provider declarations into a single `versions.tf`:

```hcl
# 1
terraform {
  required_version = ">= 1.6, < 2.0"

  # 2
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — `required_version` constrains *Terraform itself*, not providers. `>= 1.6, < 2.0` means "at least 1.6, but not any 2.x release." This protects you from breaking changes in Terraform's own behavior.
- **`# 2`** — Each entry under `required_providers` declares one provider plugin. `source` is the registry address (e.g., `hashicorp/aws` → `registry.terraform.io/hashicorp/aws`). `version` uses constraint syntax — `~> 5.60` means `>= 5.60.0, < 6.0.0`.

> **🔗 Reference:** Version constraint syntax in detail — https://developer.hashicorp.com/terraform/language/expressions/version-constraints

### Provider aliases — multiple instances of one provider

Sometimes you need two configurations of the same provider — e.g., to talk to two AWS regions, or two AWS accounts:

```hcl
# 1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# 2
provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# 3
resource "aws_s3_bucket" "us_bucket" {
  provider = aws.us_east_1
  bucket   = "my-us-bucket-xyz"
}

# 4
resource "aws_s3_bucket" "eu_bucket" {
  provider = aws.eu_west_1
  bucket   = "my-eu-bucket-xyz"
}
```

**Line-by-line:**

- **`# 1`, `# 2`** — Two `aws` provider blocks, each with a different `alias`. Without an alias, you can only have one provider config per provider per module.
- **`# 3`, `# 4`** — `provider = aws.us_east_1` explicitly tells this resource which provider config to use. Without it, Terraform uses the default (unaliased) one.

Common real-world use: ACM certificates for CloudFront *must* live in `us-east-1`, but the rest of your infrastructure is in `eu-west-1`. You'd use two aliases.

> **🔗 Reference:** Provider configuration & aliases — https://developer.hashicorp.com/terraform/language/providers/configuration

## 4.3 Resources — meta-arguments and lifecycle

Every resource accepts a few special "meta-arguments" that aren't specific to its provider:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # 1
  depends_on = [aws_internet_gateway.main]

  # 2
  count = 3
  # or for_each = toset(["a", "b", "c"])

  # 3
  provider = aws.eu_west_1

  # 4
  lifecycle {
    # 4a
    create_before_destroy = true

    # 4b
    prevent_destroy = false

    # 4c
    ignore_changes = [
      tags["LastDeployedAt"],
      ami,
    ]

    # 4d
    replace_triggered_by = [aws_security_group.web.id]
  }
}
```

**Line-by-line:**

- **`# 1`** — `depends_on` declares an *explicit* dependency. Most dependencies are implicit (Terraform sees `aws_security_group.web.id` and figures it out). Use `depends_on` only when there's a non-attribute reason for ordering — e.g., a resource that just needs to exist before another can be created.
- **`# 2`** — `count` and `for_each` create multiple instances of a resource. We cover these in §4.4.
- **`# 3`** — `provider = aws.eu_west_1` chooses which provider alias this resource uses (see §4.2 above).
- **`# 4`** — The `lifecycle` block tweaks how Terraform manages the resource:
  - **`# 4a`** — `create_before_destroy = true` makes Terraform create the new version before destroying the old. Crucial for things like ASG launch templates and load balancers where downtime matters.
  - **`# 4b`** — `prevent_destroy = true` makes `terraform destroy` (and any plan that would delete this resource) hard-fail. **Set this on production databases.**
  - **`# 4c`** — `ignore_changes` tells Terraform "if these attributes drift, don't try to fix them." Useful for tags written by AWS itself, AMI IDs that auto-update, etc.
  - **`# 4d`** — `replace_triggered_by` *forces* replacement when an unrelated attribute changes. Niche but powerful.

> **🔗 References:**
> - The Lifecycle meta-argument — https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
> - The depends_on meta-argument — https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on

## 4.4 `count` vs `for_each` — when to use which

> **📚 Background:** Both meta-arguments create multiple instances of a resource. The difference is subtle but matters enormously for change management: `count` indexes resources by integer position, while `for_each` indexes by string key. Inserting an item into the middle of a `count` list shifts every subsequent index, causing Terraform to destroy and recreate everything after it. `for_each` is stable: items added/removed only affect their own entry.

### `count` — N copies indexed by integer

```hcl
# 1
resource "aws_instance" "worker" {
  count         = 3
  ami           = "ami-..."
  instance_type = "t3.small"

  # 2
  tags = {
    Name = "worker-${count.index}"
  }
}
```

- **`# 1`** — Create 3 instances. Referenced as `aws_instance.worker[0]`, `aws_instance.worker[1]`, `aws_instance.worker[2]`.
- **`# 2`** — Inside the resource block, `count.index` is `0`, `1`, `2` for each instance.

If you later change `count = 3` to `count = 4`, no problem — instance `[3]` gets added. But if you wanted to "remove worker `[1]`", you'd have to remove it *and* shift everything else, causing recreates.

### `for_each` — keyed by a stable identifier

```hcl
# 1
resource "aws_iam_user" "team" {
  for_each = toset(["alice", "bob", "carol"])
  name     = each.key
}

# 2
resource "aws_iam_user_policy_attachment" "admin" {
  for_each   = toset(["alice", "bob"])
  user       = aws_iam_user.team[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

- **`# 1`** — Create three IAM users. Referenced as `aws_iam_user.team["alice"]`, etc. `each.key` and `each.value` are available inside the block — for `toset`, both are the string itself.
- **`# 2`** — Attach a policy only to alice and bob. Note we reference `aws_iam_user.team[each.key]` — instances are keyed by string.

Removing "bob" from the set just removes that one user — alice and carol are untouched.

### When to use which

| Use **`for_each`** when…                            | Use **`count`** when…                          |
| --------------------------------------------------- | ---------------------------------------------- |
| Items have a stable identity (name, AZ, region)     | You want "N identical copies, nothing special" |
| Items might be added or removed                     | You're using a simple `enabled ? 1 : 0` switch |
| You want to refer to one specific instance by name  | Indexes don't carry meaning                    |

> **🔗 Reference:** for_each meta-argument — https://developer.hashicorp.com/terraform/language/meta-arguments/for_each

## 4.5 The Terraform workflow — daily commands

```bash
# One-time per directory
terraform init           # Download providers, configure backend, init modules

# Hot loop
terraform fmt            # Auto-format .tf files (do this before every commit)
terraform validate       # Syntax + basic config validation
terraform plan           # Compute and show the diff
terraform apply          # Execute the diff (after y/n confirmation)

# CI mode (no prompts)
terraform plan -out=plan.tfplan
terraform apply -auto-approve plan.tfplan

# Inspection
terraform show           # Pretty-print the state
terraform output         # Show all outputs
terraform output -raw db_password   # One output, no quotes, scriptable
terraform state list     # List every resource in state
terraform state show <addr>   # Show one resource's full state

# Teardown
terraform destroy        # Plan a destroy of everything, then apply
```

## 4.6 The dependency lock file

When you run `terraform init`, Terraform creates a file called **`.terraform.lock.hcl`** in the working directory. It looks like:

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.60.0"
  constraints = "~> 5.60"
  hashes = [
    "h1:abc123...XYZ=",
    "zh:def456...UVW",
    "zh:ghi789...RST",
    # ... more hashes for each platform
  ]
}
```

> **📚 Background:** The lock file pins **exact provider versions** (the one chosen at init time) and **checksums** for those binaries. This serves two purposes:
>
> 1. **Reproducibility** — everyone on the team and CI use the *exact same* provider binary, not whatever happens to be latest within the `~> 5.60` constraint.
> 2. **Supply-chain security** — if a malicious actor compromises a provider release on the registry, the changed hash will be detected at `terraform init` and the install will fail.

**Always commit `.terraform.lock.hcl` to git.** It's not in `.gitignore` for a reason.

To upgrade providers within their constraints:

```bash
terraform init -upgrade
git diff .terraform.lock.hcl     # review the change
```

To add hashes for an additional platform (so Linux teammates can use a lock file generated on macOS):

```bash
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64
```

> **🔗 References:**
> - Dependency lock file docs — https://developer.hashicorp.com/terraform/language/files/dependency-lock
> - Supply chain attack on terraform-provider, March 2024 — read about why locking matters: https://www.bleepingcomputer.com/

---

# 5. State Management — Deep Dive

## 5.1 What's actually in the state file?

If you run `terraform show -json | jq .` on any project, you'll see something like:

```json
{
  "format_version": "1.0",
  "terraform_version": "1.9.5",
  "values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_s3_bucket.logs",
          "type": "aws_s3_bucket",
          "name": "logs",
          "provider_name": "registry.terraform.io/hashicorp/aws",
          "schema_version": 0,
          "values": {
            "id": "my-team-logs-12345",
            "arn": "arn:aws:s3:::my-team-logs-12345",
            "bucket": "my-team-logs-12345",
            "bucket_domain_name": "my-team-logs-12345.s3.amazonaws.com",
            "region": "eu-west-1",
            "tags": {
              "Environment": "prod"
            }
          }
        }
      ]
    }
  }
}
```

Every resource you've declared has a complete attribute snapshot. This is the **source of truth Terraform uses for diffing.**

> **⚠️ Gotcha — secrets in state:** Generated passwords, RDS master credentials, anything marked `sensitive = true`, AWS access keys created by IAM resources — **all stored in plain text inside the state JSON.** This is why:
>
> 1. State files **must** be encrypted at rest (S3 SSE, Azure Storage encryption, etc.).
> 2. Access to state files **must** be restricted to the minimum set of humans/roles.
> 3. State files **must never** be checked into git.

## 5.2 Why remote state is mandatory for teams

Local state (`terraform.tfstate` in your working directory) is fine for *learning*. For any team use, it's a disaster waiting to happen:

| Problem with local state             | Consequence                                        |
| ------------------------------------ | -------------------------------------------------- |
| Two people apply at once             | State file written by both → corruption            |
| Laptop lost / disk failure           | Lose the mapping between declared and real         |
| No history                           | No way to recover from a bad state edit            |
| Hard to share with CI                | Either commit state (bad) or rerun init manually   |
| Local backup is one machine          | One person becomes a single point of failure       |

A **remote backend** stores state in a shared location (S3, Azure Blob, GCS, Terraform Cloud) and enforces **locking** — only one `apply` can run against a given state at a time.

## 5.3 S3 + DynamoDB backend (AWS) — the canonical setup

> **✅ Step-by-step bootstrap**

This is the most-used pattern for AWS-based teams. You need three things:

1. An **S3 bucket** to store state files. Versioned + encrypted.
2. A **DynamoDB table** to hold locks. (Newer Terraform 1.10+ supports S3-native locking via a `.tflock` file, no DynamoDB needed.)
3. A **backend block** in each project pointing at them.

### Step 1: Create the bucket and lock table — outside of Terraform

> **📚 Background:** You can't use Terraform to create the backend that stores Terraform's state — chicken-and-egg. Create these manually (or in a *separate* "bootstrap" Terraform project with local state, applied once at the dawn of time).

```bash
# 1
aws s3api create-bucket \
  --bucket mycompany-tf-state \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

# 2
aws s3api put-bucket-versioning \
  --bucket mycompany-tf-state \
  --versioning-configuration Status=Enabled

# 3
aws s3api put-bucket-encryption \
  --bucket mycompany-tf-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
    }]
  }'

# 4
aws s3api put-public-access-block \
  --bucket mycompany-tf-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 5
aws dynamodb create-table \
  --table-name mycompany-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

**Line-by-line:**

- **`# 1`** — Create the bucket. Outside us-east-1, AWS requires `LocationConstraint` to match the region (yes, redundant with `--region`, but that's S3's API).
- **`# 2`** — Enable versioning. Now every state write is preserved as a previous version, so you can roll back a corrupted state.
- **`# 3`** — Enable server-side encryption with AES-256 (SSE-S3). For higher security, use SSE-KMS with a customer-managed key instead.
- **`# 4`** — Block all public access. The four `*=true` flags cover ACLs, policies, and combinations thereof. State buckets should *never* be public.
- **`# 5`** — Create the DynamoDB lock table. `LockID` is the partition key — Terraform writes one item per lock acquisition. `PAY_PER_REQUEST` (on-demand billing) is fine here since locks are infrequent.

### Step 2: Reference the backend in your Terraform code

```hcl
# 1
terraform {
  # 2
  backend "s3" {
    bucket         = "mycompany-tf-state"
    key            = "platform/network/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "mycompany-tf-locks"
    encrypt        = true
  }
}
```

**Line-by-line:**

- **`# 1`** — The `terraform {}` configuration block.
- **`# 2`** — `backend "s3"` declares "store state in S3."
  - `bucket` — the bucket from step 1.
  - `key` — the path *inside the bucket* where this project's state lives. Use a logical path like `platform/network/terraform.tfstate` so different stacks don't collide.
  - `region` — where the bucket is.
  - `dynamodb_table` — the lock table from step 1.
  - `encrypt = true` — tells Terraform to use SSE when writing.

### Step 3: Initialize

```bash
terraform init
# Initializing the backend...
# Successfully configured the backend "s3"!
```

Terraform writes the state to `s3://mycompany-tf-state/platform/network/terraform.tfstate` on first apply.

### Step 4: Verify locking

If you run `terraform apply` in two terminals simultaneously, the second one says:

```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc123-...
  Path:      mycompany-tf-state/platform/network/terraform.tfstate
  Operation: OperationTypeApply
  Who:       jane.doe@laptop
```

Good — that's the lock working.

### Migrating from local state

If you started with local state and want to move to a remote backend:

1. Add the `backend` block.
2. Run `terraform init`. Terraform asks "Do you want to copy existing state to the new backend?" Answer **yes**.
3. Delete the local `terraform.tfstate` files (they're now in S3).

> **🔗 References:**
> - S3 backend docs — https://developer.hashicorp.com/terraform/language/backend/s3
> - AWS S3 + DynamoDB pattern (HashiCorp blog) — https://www.hashicorp.com/blog/terraform-state-best-practices
> - S3 native locking (Terraform 1.10+) — https://developer.hashicorp.com/terraform/language/backend/s3#s3-state-locking

## 5.4 Azure Storage backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "mycompanytfstate"      # globally unique, 3-24 lowercase chars
    container_name       = "tfstate"
    key                  = "platform/network.tfstate"
  }
}
```

Bootstrap:

```bash
az group create --name tfstate-rg --location westeurope

az storage account create \
  --name mycompanytfstate \
  --resource-group tfstate-rg \
  --location westeurope \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name mycompanytfstate
```

Azure blobs have **lease-based locking built in** — no separate lock table needed.

> **🔗 Reference:** AzureRM backend docs — https://developer.hashicorp.com/terraform/language/backend/azurerm

## 5.5 GCS backend (Google Cloud)

```hcl
terraform {
  backend "gcs" {
    bucket = "mycompany-tf-state"
    prefix = "platform/network"
  }
}
```

> **🔗 Reference:** GCS backend docs — https://developer.hashicorp.com/terraform/language/backend/gcs

## 5.6 State commands you'll actually use

```bash
# 1 — Move a resource within state (when you rename it in code)
terraform state mv aws_instance.web aws_instance.web_server

# 2 — Remove a resource from state without destroying it
terraform state rm aws_instance.web

# 3 — Show one resource in detail
terraform state show aws_instance.web

# 4 — List all resources
terraform state list

# 5 — Pull state to a local file (read-only, careful!)
terraform state pull > current.tfstate

# 6 — Replace state (very dangerous — almost never use)
terraform state push current.tfstate
```

**When to use each:**

- **`# 1`** — You renamed `aws_instance.web` to `aws_instance.web_server` in your code. Without `state mv`, Terraform would destroy the old and create new. `state mv` updates state to point the new name at the existing real resource.
- **`# 2`** — You want a resource to stop being managed by Terraform but stay in the cloud. Common when extracting something into a new module — `state rm` then re-`import` under the new module path.
- **`# 3`** — Inspect everything Terraform knows about one resource. Useful for debugging.
- **`# 4`** — Quick inventory.
- **`# 5`** — Forensics. Don't edit and push it back unless you really know what you're doing — instead, use targeted `state mv`/`rm` commands.

## 5.7 Importing existing infrastructure

Sometimes you inherit cloud resources built by hand. **Importing** brings them under Terraform management.

### Old style — CLI-driven

```bash
# 1 — Write a placeholder resource block in your code
echo 'resource "aws_instance" "web" {}' >> main.tf

# 2 — Import the real resource into state
terraform import aws_instance.web i-0123456789abcdef0

# 3 — Run plan; Terraform tells you what attributes don't match
terraform plan

# 4 — Fill in the resource block to match real-world settings
# 5 — Iterate plan + edit until plan is empty
```

### New style (Terraform 1.5+) — declarative imports

```hcl
# 1
import {
  to = aws_instance.web
  id = "i-0123456789abcdef0"
}

# 2 (still needed — Terraform doesn't generate this for you unless you ask)
resource "aws_instance" "web" {
  # ... attributes ...
}
```

You can scaffold the resource block automatically:

```bash
terraform plan -generate-config-out=generated.tf
# Generated `generated.tf` contains the resource block matching reality
```

> **🔗 References:**
> - Importing existing resources — https://developer.hashicorp.com/terraform/language/import
> - `terraform import` CLI — https://developer.hashicorp.com/terraform/cli/import
> - Generating config from imports — https://developer.hashicorp.com/terraform/language/import/generating-configuration

## 5.8 State splitting — blast radius matters

> **📚 Background:** A single Terraform state with hundreds of resources becomes slow (refresh queries every resource every time) and **dangerous** (one wrong apply blasts everything). The professional pattern is to **split state by blast radius** — small isolated states that depend on each other through explicit cross-references rather than living in one giant blob.

```
                      ┌─────────────────────────────────┐
                      │  Higher layers depend on lower  │
                      │  ▼ (never the other way)        │
                      └─────────────────────────────────┘

   Layer 4: Application       service-a/, service-b/   ← changes hourly
   Layer 3: Platform          eks/, msk/, rds/         ← changes weekly
   Layer 2: Shared services   dns/, iam/, kms/         ← changes monthly
   Layer 1: Network           vpc/, tgw/               ← changes quarterly
   Layer 0: Accounts          organization, sso        ← changes yearly
```

Each box = one Terraform module with its own backend key. **Higher layers depend on lower layers; lower layers never depend on higher.** Application code changes in layer 4 should *never* require a re-plan of the VPC in layer 1.

Terragrunt makes managing dozens of these tractable. We get there in §11–12.

---

# 6. Variables, Outputs, and Locals

## 6.1 Input variables — the public interface of a module

> **📚 Background:** Variables let you parameterize a module. Without them, every project would be a one-off; with them, the same code becomes reusable. Variables have a **type**, an optional **default**, an optional **description**, and optional **validation** rules. The type system is what catches "you passed a string where I wanted a list" at plan time rather than at apply time.

```hcl
# 1
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, or prod)"

  # 2
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# 3
variable "instance_count" {
  type    = number
  default = 2
}

# 4
variable "tags" {
  type    = map(string)
  default = {}
}

# 5
variable "subnets" {
  type = list(object({
    cidr   = string
    az     = string
    public = bool
  }))
  description = "List of subnet configurations"
}

# 6
variable "db_password" {
  type      = string
  sensitive = true
}

# 7
variable "db_engine_version" {
  type    = string
  default = "16.3"
  nullable = false
}
```

**Line-by-line:**

- **`# 1`** — A simple string variable. `description` shows up in `terraform plan` and IDE tooltips — write good ones.
- **`# 2`** — A validation rule. `condition` must evaluate to `true` (or `null` for "not applicable"); otherwise, the `error_message` is shown and the plan fails. You can have multiple `validation {}` blocks per variable.
- **`# 3`** — A number with a default. Defaults make the variable optional.
- **`# 4`** — A `map(string)` for tags. Empty map default means callers can skip it entirely.
- **`# 5`** — A complex typed variable: a list of objects, each with three fields of specified types. The type system enforces this — Terraform rejects malformed inputs at plan time.
- **`# 6`** — `sensitive = true` hides the value from plan/apply output. It still ends up in state (encrypted at rest if you're doing things right) but won't be printed to the console or CI logs.
- **`# 7`** — `nullable = false` means the variable can't be set to `null`. Useful when you want to ensure a value is always provided.

> **🔗 References:**
> - Input variables — https://developer.hashicorp.com/terraform/language/values/variables
> - Variable validation — https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules
> - Type constraints — https://developer.hashicorp.com/terraform/language/expressions/type-constraints

## 6.2 Setting variables — the precedence order

There are six ways to set a variable. They have a defined precedence (later overrides earlier):

| #  | Source                                        | Example                                            |
| -- | --------------------------------------------- | -------------------------------------------------- |
| 1  | Default in `variable {}` block                | `default = "dev"`                                  |
| 2  | Environment variables                         | `export TF_VAR_environment=prod`                   |
| 3  | `terraform.tfvars` (auto-loaded)              | File in working directory                          |
| 4  | `*.auto.tfvars` (auto-loaded, alphabetical)   | `prod.auto.tfvars`                                 |
| 5  | `-var-file=foo.tfvars` flag                   | `terraform apply -var-file=prod.tfvars`            |
| 6  | `-var key=value` flag                         | `terraform apply -var environment=prod`            |

Higher numbers win. So a CLI `-var` flag overrides everything.

Example `terraform.tfvars`:

```hcl
environment    = "prod"
instance_count = 5
tags = {
  Owner      = "platform-team"
  CostCenter = "eng-1234"
}
```

> **⚠️ Gotcha:** `*.tfvars` files often contain secrets and should not be committed. Use `.gitignore` to exclude them, and provide `example.tfvars` showing the structure without real values.

## 6.3 Outputs — the public interface back to callers

> **📚 Background:** Outputs are how a module hands data back to its caller. A root module's outputs are also accessible from the CLI (`terraform output`), making them useful for both human inspection and CI scripts (`OUTPUT=$(terraform output -raw db_endpoint)`).

```hcl
# 1
output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the application load balancer"
}

# 2
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

# 3
output "endpoints" {
  value = {
    api     = "https://${aws_lb.api.dns_name}"
    web     = "https://${aws_lb.web.dns_name}"
    metrics = "https://${aws_lb.metrics.dns_name}/metrics"
  }
}

# 4
output "vpc_id" {
  value = module.vpc.vpc_id
  precondition {
    condition     = module.vpc.vpc_id != ""
    error_message = "VPC ID must not be empty"
  }
}
```

**Line-by-line:**

- **`# 1`** — Simple output. After apply, `terraform output alb_dns_name` prints the value.
- **`# 2`** — A sensitive output. Hidden from console output but still in state. Read it with `terraform output -raw db_password` (or via API).
- **`# 3`** — A structured output. The value is an object; consumers can access `endpoints.api`, `endpoints.web`, etc.
- **`# 4`** — A precondition assertion. If the condition is false at apply time, the output (and the whole apply) fails. Useful for guarding against impossible states.

Reading outputs:

```bash
terraform output                          # all outputs, formatted
terraform output alb_dns_name             # one output, with quotes
terraform output -raw alb_dns_name        # one output, no quotes (for scripting)
terraform output -json                    # machine-readable
```

> **🔗 Reference:** Output values — https://developer.hashicorp.com/terraform/language/values/outputs

## 6.4 Locals — intermediate computation

> **📚 Background:** Locals are named values inside a module. Unlike variables, they're not inputs (callers can't set them) and unlike outputs, they're not exposed. They exist purely to give names to intermediate computations — making code DRY and readable.

```hcl
# 1
locals {
  # 2
  name_prefix = "${var.project}-${var.environment}"

  # 3
  common_tags = merge(
    var.tags,
    {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
    }
  )

  # 4
  subnets = {
    for idx, az in var.availability_zones :
    az => {
      cidr_block = cidrsubnet(var.vpc_cidr, 4, idx)
      az         = az
    }
  }

  # 5
  is_prod = var.environment == "prod"

  # 6
  instance_type = local.is_prod ? "m6i.xlarge" : "t3.medium"
}
```

**Line-by-line:**

- **`# 1`** — One `locals { }` block. (You can have multiple, but one is usually clearer.)
- **`# 2`** — A simple computed string. Used elsewhere as `local.name_prefix`.
- **`# 3`** — A common-tags map. `merge()` combines maps, with later maps overriding earlier — so explicit tags override user-supplied ones. This is the canonical pattern.
- **`# 4`** — A more complex local: a map of subnets keyed by AZ, with computed CIDRs. `cidrsubnet(prefix, newbits, idx)` splits a CIDR — see §6.5.
- **`# 5`** — A boolean shortcut. `local.is_prod` reads better than repeating `var.environment == "prod"`.
- **`# 6`** — Conditional on the boolean. Notice locals can reference other locals.

> **🔗 Reference:** Local values — https://developer.hashicorp.com/terraform/language/values/locals

## 6.5 Built-in functions — the most useful ones

Terraform ships with [over 100 functions](https://developer.hashicorp.com/terraform/language/functions). You don't need to memorize them, but knowing what categories exist saves time.

### String functions

```hcl
upper("hello")                     # "HELLO"
lower("HELLO")                     # "hello"
title("hello world")               # "Hello World"
trimspace("  hello  ")             # "hello"
format("user-%03d", 7)             # "user-007"
replace("a.b.c", ".", "-")         # "a-b-c"
split(",", "a,b,c")                # ["a", "b", "c"]
join("-", ["a", "b", "c"])         # "a-b-c"
substr("hello world", 6, 5)        # "world"
regex("\\d+", "abc123def")         # "123"
regexall("\\w+", "one two three")  # ["one", "two", "three"]
```

### Collection functions

```hcl
length([1, 2, 3])                  # 3
keys({a=1, b=2})                   # ["a", "b"]
values({a=1, b=2})                 # [1, 2]
merge({a=1}, {b=2})                # {a=1, b=2}
concat([1, 2], [3, 4])             # [1, 2, 3, 4]
distinct([1, 1, 2, 3])             # [1, 2, 3]
flatten([[1, 2], [3]])             # [1, 2, 3]
contains([1, 2, 3], 2)             # true
element(["a","b","c"], 1)          # "b"
lookup({a=1, b=2}, "c", 0)         # 0 (default if key missing)
toset(["a", "b", "a"])             # ["a", "b"]
zipmap(["a","b"], [1,2])           # {a=1, b=2}
```

### Encoding functions

```hcl
jsonencode({a = 1, b = "x"})       # "{\"a\":1,\"b\":\"x\"}"
jsondecode("{\"a\":1}")            # {a = 1}
yamldecode(file("config.yml"))     # parse YAML file into a value
base64encode("hello")              # "aGVsbG8="
base64decode("aGVsbG8=")           # "hello"
```

### Filesystem functions

```hcl
file("user-data.sh")                                  # read file as string
filebase64("image.png")                               # read binary as base64
templatefile("config.tpl", { region = "eu-west-1" }) # render template
fileset(".", "**/*.json")                             # glob — returns set of paths
```

### Network functions

```hcl
cidrsubnet("10.0.0.0/16", 8, 1)    # "10.0.1.0/24" — split /16 into /24s, take idx 1
cidrhost("10.0.1.0/24", 5)         # "10.0.1.5" — get the 5th host in the subnet
cidrnetmask("10.0.0.0/16")         # "255.255.0.0"
```

### Crypto/hash functions

```hcl
sha256("payload")
md5("payload")
bcrypt("password", 10)
uuid()                              # ⚠️ not stable across runs!
uuidv5("dns", "example.com")        # ✅ deterministic UUID5
```

> **⚠️ Gotcha:** `uuid()` and `timestamp()` produce a new value every run, which causes Terraform to plan changes on every apply. Use them only inside `ignore_changes` contexts or for triggering forced replacements.

> **🔗 References:**
> - Complete function reference — https://developer.hashicorp.com/terraform/language/functions
> - `cidrsubnet` deep dive — https://developer.hashicorp.com/terraform/language/functions/cidrsubnet
> - `templatefile` examples — https://developer.hashicorp.com/terraform/language/functions/templatefile

---

## 6.6 Conditional Logic — Comprehensive Patterns

> **📚 Background:** Terraform is declarative, so it has no `if` statement that controls execution flow. Instead, conditionals are *expressions* that produce different values, and you use those values to drive resource creation, attribute assignment, and module instantiation. There are seven patterns you'll use over and over.

### Pattern 1 — Ternary expressions

The fundamental building block. `condition ? a : b`:

```hcl
# 1
locals {
  instance_type = var.environment == "prod" ? "m6i.xlarge" : "t3.medium"

  # 2
  backup_retention_days = var.environment == "prod" ? 30 : (
    var.environment == "staging" ? 14 : 7
  )

  # 3
  enable_multi_az = contains(["prod", "staging"], var.environment)
}
```

**Line-by-line:**

- **`# 1`** — Standard ternary. Read as "if prod, then m6i.xlarge, else t3.medium."
- **`# 2`** — Nested ternary for three-way branching. Always parenthesize for readability — even when not strictly required.
- **`# 3`** — A boolean expression is itself a conditional value; no ternary needed.

> **⚠️ Gotcha:** both branches of a ternary must produce the **same type**. `cond ? "yes" : 0` will fail because string and number don't unify. If you need different types, use a different pattern.

### Pattern 2 — Conditional resource creation with `count`

The most common pattern for "create this only if a flag is set":

```hcl
# 1
variable "enable_cloudwatch_alarm" {
  type    = bool
  default = false
}

# 2
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_cloudwatch_alarm ? 1 : 0

  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
}

# 3
output "alarm_arn" {
  value = var.enable_cloudwatch_alarm ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}
```

**Line-by-line:**

- **`# 1`** — A toggle variable.
- **`# 2`** — `count = condition ? 1 : 0` either creates the resource (count=1) or doesn't (count=0). When created, the resource is addressed as `aws_cloudwatch_metric_alarm.high_cpu[0]` — note the `[0]` index even though there's only one.
- **`# 3`** — Reference the resource conditionally. Without the ternary, `aws_cloudwatch_metric_alarm.high_cpu[0].arn` would crash when count=0 (index out of bounds).

> **⚠️ Gotcha:** if you reference a count-based conditional resource elsewhere, **always** wrap with a ternary. The common pattern: `var.enable_x ? aws_x.this[0].arn : null`.

### Pattern 3 — `count` as a list filter

`count` can be more than a bool — it's a number, so any expression producing a count works:

```hcl
# Create one bucket per environment, but only for prod and staging
locals {
  environments_needing_bucket = [
    for e in ["dev", "staging", "prod"] : e if e != "dev"
  ]
}

resource "aws_s3_bucket" "logs" {
  count  = length(local.environments_needing_bucket)
  bucket = "logs-${local.environments_needing_bucket[count.index]}"
}
```

But this gets tangled fast. **Prefer `for_each` with a conditional filter** (next pattern) for anything beyond a simple toggle.

### Pattern 4 — `for_each` with conditional filtering

```hcl
# 1
variable "users" {
  type = map(object({
    role           = string
    enable_console = bool
  }))
  default = {
    alice = { role = "admin",     enable_console = true  }
    bob   = { role = "developer", enable_console = true  }
    carol = { role = "developer", enable_console = false }
    dave  = { role = "billing",   enable_console = false }
  }
}

# 2
resource "aws_iam_user" "this" {
  for_each = var.users
  name     = each.key
}

# 3
resource "aws_iam_user_login_profile" "console" {
  for_each = {
    for name, cfg in var.users : name => cfg
    if cfg.enable_console
  }

  user = aws_iam_user.this[each.key].name
}

# 4
resource "aws_iam_user_policy_attachment" "admin" {
  for_each = {
    for name, cfg in var.users : name => cfg
    if cfg.role == "admin"
  }

  user       = aws_iam_user.this[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

**Line-by-line:**

- **`# 1`** — A map of users with per-user config.
- **`# 2`** — Create every user.
- **`# 3`** — Create console login profiles **only for users with `enable_console = true`**. The expression `for name, cfg in var.users : name => cfg if cfg.enable_console` is a *for-expression with a filter*: iterate, keep only entries where the predicate is true, build a new map.
- **`# 4`** — Same pattern: attach the admin policy only to admin users.

The big win: adding a new user (or changing one user's `enable_console`) only touches that user's resources. No index shifting, no surprise replacements.

> **🔗 References:**
> - For expressions (with filters) — https://developer.hashicorp.com/terraform/language/expressions/for
> - `for_each` meta-argument — https://developer.hashicorp.com/terraform/language/meta-arguments/for_each

### Pattern 5 — `dynamic` blocks for conditional nested blocks

Some resources have **nested blocks** that can appear zero, one, or many times. `dynamic` generates them programmatically:

```hcl
variable "ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

resource "aws_security_group" "this" {
  name   = var.name
  vpc_id = var.vpc_id

  # 1
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # 2
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.bastion_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Line-by-line:**

- **`# 1`** — A `dynamic "ingress"` block iterates over `var.ingress_rules`. For each item, it generates one `ingress { ... }` block. Inside `content`, the iterator name (`ingress`) is the block label; `ingress.value` is the current item; `ingress.key` is the index/key.
- **`# 2`** — The same pattern as Pattern 2 but for nested blocks. `for_each = condition ? [1] : []` creates either one block or zero. This is the standard "conditional nested block" idiom.

> **🔗 Reference:** Dynamic blocks — https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks

### Pattern 6 — Conditional module instantiation

You can't have `count` or `for_each` at the top level of a `module {}` block in older Terraform versions, but you can in **Terraform 0.13+**:

```hcl
# 1
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  cluster_name = var.cluster_name
  environment  = var.environment
}

# 2
output "monitoring_dashboard_url" {
  value = var.enable_monitoring ? module.monitoring[0].dashboard_url : null
}

# 3
module "regional_apps" {
  source   = "./modules/app"
  for_each = toset(var.enabled_regions)

  region       = each.key
  environment  = var.environment
  providers = {
    aws = aws.regional[each.key]
  }
}
```

**Line-by-line:**

- **`# 1`** — Conditional module: create the monitoring stack only when enabled.
- **`# 2`** — Reference its output safely.
- **`# 3`** — `for_each` on a module — one instantiation per region, each with its own provider alias. Powerful pattern for multi-region deployments.

### Pattern 7 — `coalesce`, `coalescelist`, and `try` for fallbacks

`coalesce()` returns the first non-null/non-empty argument:

```hcl
locals {
  # 1
  bucket_name = coalesce(var.bucket_name, "${var.project}-${var.environment}-data")

  # 2
  tags = coalesce(var.tags, {})

  # 3
  subnet_ids = coalescelist(var.override_subnet_ids, data.aws_subnets.default.ids)
}
```

**Line-by-line:**

- **`# 1`** — If the caller provided `bucket_name`, use it; otherwise compute a default.
- **`# 2`** — Treat missing tags as empty map.
- **`# 3`** — `coalescelist` is the list version. Use overrides if provided, otherwise auto-discover.

`try()` (covered in detail in 6.7) is `coalesce`'s sibling — it returns the first argument that doesn't throw an error, useful for tolerating missing keys in objects.

### Pattern 8 — Conditional locals with `merge`

Building config objects piecewise:

```hcl
locals {
  # 1
  base_tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }

  # 2
  env_tags = var.environment == "prod" ? {
    OnCallTeam   = "platform"
    SLO          = "99.9"
    BackupPolicy = "daily"
  } : {}

  # 3
  cost_tags = var.cost_center != null ? {
    CostCenter = var.cost_center
  } : {}

  # 4
  all_tags = merge(local.base_tags, local.env_tags, local.cost_tags, var.extra_tags)
}
```

**Line-by-line:**

- **`# 1`** — Always-present tags.
- **`# 2`** — Extra tags only for prod (empty map otherwise — merges as no-op).
- **`# 3`** — Optional tag controlled by an input.
- **`# 4`** — Merge in order; later maps override earlier. `var.extra_tags` last so callers can override anything.

This is much cleaner than a single big ternary that constructs the whole map.

### Summary table

| Need                                       | Pattern                                          |
| ------------------------------------------ | ------------------------------------------------ |
| Pick between two scalar values             | Ternary: `cond ? a : b`                          |
| Create-or-don't-create a resource          | `count = cond ? 1 : 0`                           |
| Create N resources keyed by name           | `for_each = toset(...)`                          |
| Create resources only for matching items   | `for_each = { for k,v in m : k=>v if cond }`     |
| Conditional nested blocks                  | `dynamic "block" { for_each = cond ? [1] : [] }` |
| Conditional whole module                   | `module "x" { count = cond ? 1 : 0 }`            |
| Fallback to default if input is null/empty | `coalesce(input, default)`                       |
| Build config in layers                     | `merge(base, conditional_extras, ...)`           |
| Tolerate missing keys                      | `try(deep.nested.key, default)`                  |

## 6.7 Error Handling, Validation, and Defensive Programming

> **📚 Background:** Terraform has *no exceptions*. Errors at plan or apply time either pass or fail the whole operation. Your "error handling" toolkit is therefore about **preventing bad inputs from reaching apply time** — through type constraints, validation rules, preconditions, postconditions, and the `try()`/`can()` escape hatches.

### Tool 1 — Type constraints

The first line of defense. Wrong type = plan fails immediately with a clear error:

```hcl
# 1 — Simple types
variable "name"      { type = string }
variable "replicas"  { type = number }
variable "enabled"   { type = bool }

# 2 — Collections
variable "azs"       { type = list(string) }
variable "tags"      { type = map(string) }
variable "users"     { type = set(string) }

# 3 — Objects with required fields
variable "db_config" {
  type = object({
    engine    = string
    version   = string
    instance_class = string
    storage_gb = number
  })
}

# 4 — Objects with optional fields (Terraform 1.3+)
variable "alarm_config" {
  type = object({
    enabled              = optional(bool, false)
    threshold            = optional(number, 80)
    evaluation_periods   = optional(number, 2)
    notification_arns    = optional(list(string), [])
  })
  default = {}
}

# 5 — Lists of objects
variable "subnets" {
  type = list(object({
    cidr   = string
    az     = string
    public = bool
  }))
}

# 6 — The `any` escape hatch — use sparingly
variable "untyped_blob" {
  type = any
}
```

**Line-by-line:**

- **`# 1-2`** — Basic types. Terraform rejects `replicas = "five"` at plan time with a type error.
- **`# 3`** — An object with three required fields. Missing any → error.
- **`# 4`** — **The `optional()` modifier** (Terraform 1.3+) marks object fields as optional and provides defaults. This means the caller doesn't have to supply every field. The second arg is the default.
- **`# 5`** — A list of objects — common pattern for "config table" style inputs.
- **`# 6`** — `any` disables type checking. Useful for pass-through wrappers but loses safety. Avoid where possible.

> **🔗 Reference:** Type constraints — https://developer.hashicorp.com/terraform/language/expressions/type-constraints

### Tool 2 — Variable validation

The second line of defense. Reject inputs that pass type-check but are semantically wrong:

```hcl
variable "environment" {
  type        = string
  description = "Environment name"

  # 1
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  type = string

  # 2
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }

  # 3
  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "vpc_cidr must be /24 or larger (smaller number = more addresses)."
  }
}

variable "instance_count" {
  type = number

  # 4
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "instance_count must be between 1 and 100."
  }
}

variable "tags" {
  type = map(string)

  # 5 — Cross-attribute validation
  validation {
    condition     = contains(keys(var.tags), "Owner")
    error_message = "tags must include an 'Owner' key."
  }

  validation {
    condition = alltrue([
      for k, v in var.tags : length(k) <= 128 && length(v) <= 256
    ])
    error_message = "tag keys must be <= 128 chars and values <= 256 chars."
  }
}

# 6 — Variable referencing other variables (Terraform 1.9+)
variable "max_replicas" {
  type = number
}

variable "min_replicas" {
  type = number

  validation {
    condition     = var.min_replicas <= var.max_replicas
    error_message = "min_replicas must be <= max_replicas."
  }
}
```

**Line-by-line:**

- **`# 1`** — Whitelist validation. `contains(list, item)` returns true if item is in the list.
- **`# 2`** — `can()` returns true if the inner expression succeeds. Here we test whether `cidrhost(cidr, 0)` would work — a clean way to validate "is this a parseable CIDR?" without writing a regex.
- **`# 3`** — A second validation block. Each block is independent; all must pass.
- **`# 4`** — Numeric range check.
- **`# 5`** — Validating structure of a complex value. `alltrue([...])` returns true only if every element is true — perfect with a `for` expression.
- **`# 6`** — **Cross-variable validation** (Terraform 1.9+). Earlier versions only allowed `var.SELF` inside the validation block; modern versions allow any variable.

> **🔗 Reference:** Variable validation — https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules

### Tool 3 — Resource preconditions and postconditions

Validations *inside* resources, checked at plan and apply time. Useful for assertions that depend on computed values:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  # 1
  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "Selected AMI ${self.id} is not x86_64."
    }
    postcondition {
      condition     = self.root_device_type == "ebs"
      error_message = "AMI ${self.id} must be EBS-backed (got ${self.root_device_type})."
    }
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # 2
  lifecycle {
    precondition {
      condition     = contains(["t3.micro", "t3.small", "t3.medium", "m6i.large"], var.instance_type)
      error_message = "instance_type ${var.instance_type} is not in the approved list."
    }
    precondition {
      condition     = data.aws_subnet.target.vpc_id == var.expected_vpc_id
      error_message = "Subnet ${var.subnet_id} is in unexpected VPC ${data.aws_subnet.target.vpc_id}."
    }

    postcondition {
      condition     = self.private_ip != ""
      error_message = "Instance failed to receive a private IP."
    }
  }
}

data "aws_subnet" "target" {
  id = var.subnet_id
}
```

**Line-by-line:**

- **`# 1`** — `postcondition` runs **after** the data source resolves. `self` refers to this data source's resolved attributes. Useful for asserting "the thing we found matches our assumptions."
- **`# 2`** — `precondition` runs **before** the resource is planned. Use to check inputs and related data. Failure aborts the plan with your error message — much more useful than a confusing apply-time error.
- **`postcondition` on resources** runs after apply. Use to verify post-creation invariants ("the instance has a private IP", "the bucket policy actually denies public access").

> **🔗 Reference:** Custom conditions — https://developer.hashicorp.com/terraform/language/expressions/custom-conditions

### Tool 4 — `check` blocks (Terraform 1.5+)

Standalone assertions independent of any resource. Failures produce **warnings**, not errors — useful for monitoring rather than gating:

```hcl
# 1
check "ssl_cert_expiry" {
  data "aws_acm_certificate" "this" {
    domain = var.domain
  }

  assert {
    condition     = timecmp(plantimestamp(), timeadd(data.aws_acm_certificate.this.not_after, "-720h")) == -1
    error_message = "ACM certificate for ${var.domain} expires in less than 30 days."
  }
}

# 2
check "minimum_node_count" {
  assert {
    condition     = length(module.eks.node_groups["general"].instance_ids) >= 3
    error_message = "general node group has fewer than 3 nodes — capacity risk."
  }
}
```

**Line-by-line:**

- **`# 1`** — A check block can include its own data sources (scoped to just this check). Here we look up an ACM cert and warn if it expires within 30 days. Doesn't fail the apply — just shows in plan output.
- **`# 2`** — A scoped assertion. Useful for "I expect at least N of these — alert me when that's not the case."

> **🔗 Reference:** Check blocks — https://developer.hashicorp.com/terraform/language/checks

### Tool 5 — `try()` for tolerating missing attributes

`try()` evaluates each argument in order and returns the first that doesn't error:

```hcl
locals {
  # 1
  region = try(var.config.region, "eu-west-1")

  # 2
  db_password = try(
    data.aws_secretsmanager_secret_version.db.secret_string,
    var.db_password_fallback,
    "PLACEHOLDER_REPLACE_ME"
  )

  # 3
  shared_tags = try(yamldecode(file("${path.module}/tags.yml")), {})
}
```

**Line-by-line:**

- **`# 1`** — If `var.config` is missing the `region` key, fall back to a default. Without `try`, this would crash.
- **`# 2`** — Multi-level fallback chain.
- **`# 3`** — If `tags.yml` doesn't exist or is malformed, fall back to empty map.

> **⚠️ Gotcha:** `try()` swallows *all* errors silently. Don't use it as a band-aid for real bugs — use it only for genuinely-optional values.

### Tool 6 — `can()` for capability tests

`can()` returns a boolean indicating whether an expression succeeds:

```hcl
locals {
  # 1
  has_aws_credentials = can(data.aws_caller_identity.current.account_id)

  # 2
  is_valid_json = can(jsondecode(var.config_string))

  # 3
  is_ipv6 = can(regex("^[0-9a-fA-F:]+$", var.address))
}

variable "config_string" {
  type = string

  validation {
    condition     = can(jsondecode(var.config_string))
    error_message = "config_string must be valid JSON."
  }
}
```

**Use cases:**
- **`# 1-3`** — Boolean tests for "is this thing usable?"
- Most commonly used **inside `validation` blocks** to test parseability.

> **🔗 References:**
> - `try` function — https://developer.hashicorp.com/terraform/language/functions/try
> - `can` function — https://developer.hashicorp.com/terraform/language/functions/can

### Tool 7 — Defensive defaults

```hcl
variable "subnet_ids" {
  type    = list(string)
  default = []
}

# 1
resource "aws_db_subnet_group" "this" {
  count      = length(var.subnet_ids) > 0 ? 1 : 0
  name       = var.name
  subnet_ids = var.subnet_ids
}

# 2
locals {
  effective_subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default.ids
}

# 3
resource "aws_lb" "main" {
  count    = length(local.effective_subnet_ids) >= 2 ? 1 : 0
  name     = var.name
  subnets  = local.effective_subnet_ids
  internal = false

  lifecycle {
    precondition {
      condition     = length(local.effective_subnet_ids) >= 2
      error_message = "An ALB requires at least 2 subnets in different AZs (got ${length(local.effective_subnet_ids)})."
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — Don't try to create a DB subnet group with zero subnets — skip it entirely.
- **`# 2`** — Fallback chain: prefer caller-supplied subnets; otherwise auto-discover defaults.
- **`# 3`** — Belt-and-suspenders: both a count-guard *and* a precondition. The precondition gives a clear error if the count-guard is somehow bypassed.

### Tool 8 — Handling eventually-consistent and flaky APIs

Some clouds occasionally return stale data right after a write. Patterns to mitigate:

```hcl
# 1 — Force a delay before dependent resources
resource "time_sleep" "wait_for_iam" {
  depends_on      = [aws_iam_role.this, aws_iam_role_policy.this]
  create_duration = "30s"
}

resource "aws_lambda_function" "this" {
  role = aws_iam_role.this.arn
  # ... other args
  depends_on = [time_sleep.wait_for_iam]
}

# 2 — Tolerate transient state during refresh
resource "aws_eks_cluster" "this" {
  # ...
  lifecycle {
    ignore_changes = [
      # EKS sometimes reports vpc_config in different orderings
      vpc_config[0].subnet_ids,
    ]
  }
}

# 3 — Retry-friendly module sources (provider-level)
provider "aws" {
  region = var.region
  retry_mode  = "adaptive"
  max_retries = 10
}
```

**Line-by-line:**

- **`# 1`** — IAM is famously eventually-consistent: a role you just created may not be visible to Lambda yet. The `time_sleep` resource creates a 30s pause.
- **`# 2`** — Sometimes attributes "flap" between equivalent representations. `ignore_changes` prevents Terraform from continually trying to "fix" them.
- **`# 3`** — Provider-level retry. The AWS provider's adaptive retry mode handles throttling gracefully — combined with a higher `max_retries`, it survives noisy CI environments.

### A complete defensive resource example

Putting it all together — a "production-grade" resource that defends itself:

```hcl
variable "bucket_name" {
  type        = string
  description = "S3 bucket name"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket names must be 3-63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "S3 bucket names must be lowercase alphanumeric/dot/hyphen, starting and ending with alphanumeric."
  }

  validation {
    condition     = !can(regex("\\.\\.", var.bucket_name))
    error_message = "S3 bucket names cannot contain consecutive dots."
  }
}

variable "lifecycle_rules" {
  type = list(object({
    id              = string
    enabled         = bool
    expiration_days = optional(number)
    transition_to_ia_days = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules :
      r.expiration_days == null || r.expiration_days > 0
    ])
    error_message = "lifecycle_rules.*.expiration_days must be positive when set."
  }
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.expected_account_id
      error_message = "Refusing to create bucket in unexpected AWS account."
    }

    postcondition {
      condition     = self.region == var.region
      error_message = "Bucket created in unexpected region: ${self.region}"
    }

    prevent_destroy = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content { days = rule.value.expiration_days }
      }

      dynamic "transition" {
        for_each = rule.value.transition_to_ia_days != null ? [1] : []
        content {
          days          = rule.value.transition_to_ia_days
          storage_class = "STANDARD_IA"
        }
      }
    }
  }
}

data "aws_caller_identity" "current" {}

variable "expected_account_id" { type = string }
variable "region"              { type = string }
```

This single example uses: type constraints, `optional()` fields, three layers of validation (length, regex match, structural), preconditions, postconditions, `prevent_destroy`, conditional resource creation via `count`, dynamic blocks with conditional generation, and `can(regex())` for pattern checking. All standard Terraform — no extensions, no hacks.

## 6.8 Putting Conditionals and Validation Together — A Real Module

Here's a "deploy-this-app" module that uses every pattern from §6.6 and §6.7. Walk through it as a capstone exercise.

```hcl
# variables.tf

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "replicas" {
  type    = number
  default = null   # null = compute from environment

  validation {
    condition     = var.replicas == null || (var.replicas >= 1 && var.replicas <= 50)
    error_message = "replicas must be between 1 and 50, or null for auto."
  }
}

variable "high_availability" {
  type    = bool
  default = null   # null = compute from environment
}

variable "alarms" {
  type = object({
    cpu_threshold     = optional(number, 80)
    memory_threshold  = optional(number, 85)
    notification_arns = optional(list(string), [])
  })
  default = {}
}

variable "custom_tags" {
  type    = map(string)
  default = {}
}

# locals.tf

locals {
  # 1 — Derived defaults
  is_prod = var.environment == "prod"

  # 2 — Fallback chain for replicas
  effective_replicas = coalesce(
    var.replicas,
    local.is_prod ? 6 : (var.environment == "staging" ? 3 : 1)
  )

  # 3 — Fallback chain for HA
  effective_ha = var.high_availability != null ? var.high_availability : local.is_prod

  # 4 — Build tags in layers
  base_tags = {
    Project     = "myapp"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  prod_only_tags = local.is_prod ? {
    Compliance = "PCI"
    Backup     = "daily"
  } : {}
  tags = merge(local.base_tags, local.prod_only_tags, var.custom_tags)

  # 5 — Alarm enablement
  alarms_enabled = length(var.alarms.notification_arns) > 0
}

# main.tf

# 6 — Multi-AZ deployment only when HA is on
resource "aws_subnet" "this" {
  for_each = local.effective_ha ? toset(["a", "b", "c"]) : toset(["a"])
  # ...
}

# 7 — Conditional alarms
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = local.alarms_enabled ? 1 : 0

  alarm_name          = "myapp-${var.environment}-cpu"
  threshold           = var.alarms.cpu_threshold
  alarm_actions       = var.alarms.notification_arns
  # ...

  lifecycle {
    precondition {
      condition     = var.alarms.cpu_threshold > 0 && var.alarms.cpu_threshold <= 100
      error_message = "cpu_threshold must be in (0, 100]."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  count = local.alarms_enabled ? 1 : 0
  # ... similar
}

# outputs.tf

output "replica_count" {
  value = local.effective_replicas
}

output "alarm_arns" {
  value = local.alarms_enabled ? concat(
    aws_cloudwatch_metric_alarm.cpu[*].arn,
    aws_cloudwatch_metric_alarm.memory[*].arn,
  ) : []
}
```

**What's going on:**

- **Inputs** are typed and validated; `optional()` provides per-field defaults inside an object.
- **`null` as a "compute it" sentinel** lets callers pass nothing and get sensible defaults.
- **Locals derive the effective configuration** through fallback chains — the caller's value if set, otherwise an env-driven default.
- **Tags are built in layers** with `merge`.
- **Resources are conditional** on derived booleans (`effective_ha`, `alarms_enabled`).
- **Preconditions** guard against semantically-invalid combinations that pass type-check.
- **Outputs handle the no-alarms case** by returning an empty list rather than crashing.

This is what a real production module looks like. There's a lot, but every piece earns its place.

---

# 7. Modules and Reusability

## 7.1 Anatomy of a module

A module is **a folder of `.tf` files**. That's it. The convention is to organize files by role:

```
modules/vpc/
├── main.tf          # The actual resources
├── variables.tf     # All variable {} blocks
├── outputs.tf       # All output {} blocks
├── versions.tf      # terraform {} block with required_providers
├── locals.tf        # locals {} blocks (optional)
├── README.md        # Documentation (auto-generated by terraform-docs)
└── examples/
    ├── basic/       # Minimal usage example
    │   ├── main.tf
    │   └── README.md
    └── full/        # All features turned on
        └── main.tf
```

Smaller modules might be just `main.tf` + `variables.tf` + `outputs.tf`. Larger ones may split `main.tf` into `iam.tf`, `network.tf`, `compute.tf`, etc.

## 7.2 Calling a local module

```hcl
# 1
module "vpc" {
  source = "../../modules/vpc"

  # 2
  name = "platform-prod"
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

# 3
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

**Line-by-line:**

- **`# 1`** — `module "vpc"` — the local name. `source = "../../modules/vpc"` — relative path to the module folder. Terraform handles relative paths from the file the `module` block is in.
- **`# 2`** — Inputs to the module. These match `variable {}` declarations inside the module.
- **`# 3`** — Reading an output from the module. `module.<name>.<output_name>` is the syntax.

## 7.3 Calling a registry module

The [Terraform Registry](https://registry.terraform.io) hosts community-vetted modules. The most reliable ones come from the [terraform-aws-modules](https://github.com/terraform-aws-modules) GitHub org.

```hcl
module "vpc" {
  # 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  # 2
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false              # 3
  enable_dns_hostnames = true

  tags = local.common_tags
}
```

**Line-by-line:**

- **`# 1`** — `source = "terraform-aws-modules/vpc/aws"` is the Registry path. It parses as `<namespace>/<name>/<provider>`. The Registry serves modules from the [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) GitHub repo.
- **`# 2`** — `version = "5.13.0"` pins to a specific release tag. **Always pin.** Use a constraint like `~> 5.13` if you want patch updates; pin exactly for highest stability.
- **`# 3`** — One of the module's many optional inputs. `single_nat_gateway = false` deploys one NAT Gateway per AZ for high availability (more expensive but no SPOF).

> **🔗 References:**
> - Public Terraform Registry — https://registry.terraform.io/
> - The terraform-aws-modules org — https://github.com/terraform-aws-modules
> - VPC module docs — https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
> - EKS module docs — https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
> - RDS module docs — https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest

## 7.4 Calling a git module

For private modules in your organization, git URLs are the most common pattern:

```hcl
module "vpc" {
  source = "git::https://github.com/mycompany/tf-modules.git//vpc?ref=v1.4.0"
  # ...
}
```

Anatomy of that URL:

```
git::https://github.com/mycompany/tf-modules.git //vpc            ?ref=v1.4.0
└┬┘  └────────────┬────────────────────────────┘ └┬─┘             └────┬───┘
 │                │                               │                    │
 │                │                               │                    └── Git ref (tag, branch, or commit)
 │                │                               └── Subdirectory inside the repo
 │                └── Repo URL
 └── Force git protocol (vs. trying to guess)
```

For SSH access (private repos):

```hcl
source = "git::ssh://git@github.com/mycompany/tf-modules.git//vpc?ref=v1.4.0"
```

**Pinning to a tag** (`?ref=v1.4.0`) is the recommended pattern — semantic versioning gives you a clean promotion story between environments.

> **🔗 Reference:** Module sources — https://developer.hashicorp.com/terraform/language/modules/sources

## 7.5 Module design principles

A good module:

1. **Has a single, clear purpose.** "Create a VPC." Not "create a VPC and an EKS cluster and a CI pipeline."
2. **Takes simple inputs.** Sensible defaults > unbounded flexibility. Don't expose every knob of every underlying resource; you'll regret it.
3. **Returns useful outputs.** IDs, ARNs, DNS names, endpoints — anything callers will need to reference.
4. **Is composable.** The outputs of one module are the inputs of another.
5. **Is versioned.** Tag releases (`v1.0.0`, `v1.1.0`); follow semantic versioning.
6. **Is documented.** README, examples, inputs/outputs tables (use [`terraform-docs`](https://terraform-docs.io/)).
7. **Is tested.** Static analysis at minimum; integration tests via [Terratest](https://terratest.gruntwork.io/) for important modules.

### Example: a small but well-designed module

`modules/s3-bucket/main.tf`:

```hcl
# 1
resource "aws_s3_bucket" "this" {
  bucket = var.name
  tags   = var.tags
}

# 2
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# 3
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# 4
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — The bucket itself. `this` is a convention for "the main resource of a module" — since the module is the bucket module, the bucket is "this."
- **`# 2`** — Versioning is configured *separately* from the bucket (an AWS API quirk Terraform mirrors). Always enable versioning unless you have a strong reason not to.
- **`# 3`** — Encryption configuration. Conditional logic: if a KMS key ARN was provided, use KMS; otherwise default to AWS-managed SSE-S3.
- **`# 4`** — Block all forms of public access. The 4 flags cover ACLs (legacy access mechanism), policies, and combinations.
- **`# 5`** — A `dynamic` block. Lifecycle rules are optional, configured via a list variable. The `count = length(...) > 0 ? 1 : 0` skips this resource entirely if no rules are configured. The inner `dynamic "rule"` iterates over the list; the further-inner `dynamic "expiration"` is conditional on whether each rule sets an expiration.

`modules/s3-bucket/variables.tf`:

```hcl
variable "name" {
  type        = string
  description = "S3 bucket name (must be globally unique)"
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 63
    error_message = "S3 bucket names must be 3-63 characters."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "If provided, use this KMS key for encryption; otherwise use SSE-S3 (AES256)."
}

variable "lifecycle_rules" {
  type = list(object({
    id              = string
    enabled         = bool
    expiration_days = optional(number)
  }))
  default = []
}
```

`modules/s3-bucket/outputs.tf`:

```hcl
output "id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "domain_name" {
  description = "Bucket regional domain name (for use as origin in CloudFront, etc.)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
```

### Using the module

```hcl
module "logs_bucket" {
  source  = "git::https://github.com/mycompany/tf-modules.git//s3-bucket?ref=v1.0.0"
  name    = "mycompany-prod-logs-${data.aws_caller_identity.current.account_id}"
  tags    = local.common_tags

  lifecycle_rules = [
    {
      id              = "expire-old"
      enabled         = true
      expiration_days = 90
    }
  ]
}
```

That's the whole pattern: define a small, focused module once; use it everywhere with different inputs.

## 7.6 Layered / "stack" architecture for teams

For real organizations, organize modules into **layers**, each with its own state file:

```
┌──────────────────────────────────────────────────────────────────┐
│ Layer 4: Application                                              │
│   service-a/, service-b/, …  ← deployed by app teams              │
├──────────────────────────────────────────────────────────────────┤
│ Layer 3: Platform                                                 │
│   eks/, ecs/, rds/, msk/  ← long-lived shared infrastructure      │
├──────────────────────────────────────────────────────────────────┤
│ Layer 2: Shared services                                          │
│   dns/, iam-baselines/, kms-keys/, acm-certs/                     │
├──────────────────────────────────────────────────────────────────┤
│ Layer 1: Network                                                  │
│   vpc/, transit-gateway/, vpn/                                    │
├──────────────────────────────────────────────────────────────────┤
│ Layer 0: Accounts                                                 │
│   aws-organizations/, sso-setup/, account-baselines/              │
└──────────────────────────────────────────────────────────────────┘
```

Rules:

1. **Higher layers depend on lower layers.** App in layer 4 depends on EKS in layer 3 depends on VPC in layer 1. ✅
2. **Lower layers never depend on higher layers.** VPC doesn't know or care which apps run on top. ✅
3. **Each layer has its own state file.** An apply in layer 4 cannot accidentally destroy layer 1.
4. **Cross-layer data passes through outputs.** Layer 1's VPC ID is an output; layer 3 reads it via `terraform_remote_state` or Terragrunt `dependency`.

We expand this thoroughly with Terragrunt in §11–12.

---

# 8. Your First Project — Local Docker

> **📚 Why start here:** Cloud accounts cost money and have rate limits, IAM complexity, and slower iteration. The [`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest) provider lets you practice the entire Terraform workflow against containers on your laptop. Every concept — providers, resources, modules, dependencies, plan/apply/destroy — works identically.

## 8.1 Setup

> **✅ Step-by-step**

**Step 1**: Make sure Docker is running:

```bash
docker run --rm hello-world
# Hello from Docker! ...
```

**Step 2**: Create a project directory:

```bash
mkdir tf-docker-demo && cd tf-docker-demo
```

**Step 3**: Declare the provider in `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # By default talks to the Docker daemon socket the CLI uses.
  # On macOS/Windows: /var/run/docker.sock proxied by Docker Desktop.
  # On Linux: /var/run/docker.sock directly.
  # Override with:
  #   host = "tcp://remote-docker.example.com:2375"
}
```

> **🔗 Reference:** Docker provider docs — https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs

## 8.2 A single nginx container — annotated

`main.tf`:

```hcl
# 1
resource "docker_image" "nginx" {
  name         = "nginx:1.27-alpine"
  keep_locally = true
}

# 2
resource "docker_container" "nginx" {
  name  = "tf-nginx"
  image = docker_image.nginx.image_id

  # 3
  ports {
    internal = 80
    external = 8080
  }

  # 4
  restart = "unless-stopped"

  # 5
  env = [
    "NGINX_HOST=localhost",
  ]
}

# 6
output "url" {
  value = "http://localhost:${docker_container.nginx.ports[0].external}"
}
```

**Line-by-line:**

- **`# 1`** — Pull the nginx image. `keep_locally = true` says: don't delete the image when this resource is destroyed (faster on the next apply since the image is cached).
- **`# 2`** — Create a container from the image. Notice the implicit dependency: we reference `docker_image.nginx.image_id`, so Terraform knows to pull the image first.
- **`# 3`** — Port mapping. `internal = 80` is the container's port; `external = 8080` is the host's. Like `docker run -p 8080:80`.
- **`# 4`** — Restart policy. `unless-stopped` matches Docker's most common default.
- **`# 5`** — Environment variables. A list of `KEY=VALUE` strings.
- **`# 6`** — Output the URL. We reference the container's actual exposed port via `.ports[0].external` — using the *real* value from state, not just hardcoding 8080.

### Apply it

```bash
# 1
terraform init
# Initializing the backend...
# Initializing provider plugins...
# - Finding kreuzwerker/docker versions matching "~> 3.0"...
# - Installing kreuzwerker/docker v3.0.2...
# Terraform has been successfully initialized!

# 2
terraform plan
# Plan: 2 to add, 0 to change, 0 to destroy.

# 3
terraform apply -auto-approve
# docker_image.nginx: Creating...
# docker_image.nginx: Creation complete after 3s [id=sha256:abc...]
# docker_container.nginx: Creating...
# docker_container.nginx: Creation complete after 1s [id=def456...]

# 4
curl $(terraform output -raw url)
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...

# 5
docker ps | grep tf-nginx
# def456...   nginx:1.27-alpine   "/docker-entrypoint.…"   1 minute ago   Up   0.0.0.0:8080->80/tcp   tf-nginx

# 6
terraform destroy -auto-approve
# docker_container.nginx: Destroying...
# docker_container.nginx: Destruction complete after 0s
```

**Walkthrough:**

- **`# 1`** — `init` downloads the docker provider binary into `.terraform/providers/`.
- **`# 2`** — `plan` shows the two resources that would be created.
- **`# 3`** — `apply` runs the plan. The image takes ~3 seconds to pull; the container starts in 1 second.
- **`# 4`** — Hit the URL. nginx's welcome page.
- **`# 5`** — Confirm via the Docker CLI.
- **`# 6`** — Tear everything down.

> **🔗 Reference:** `docker_container` resource — https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container

## 8.3 Multi-container app with a network

Let's deploy a small app: a Redis container plus a "voting" web app that talks to it.

`main.tf`:

```hcl
# 1
resource "docker_network" "app" {
  name = "tf-app-net"
}

# 2
resource "docker_image" "redis" {
  name = "redis:7-alpine"
}

# 3
resource "docker_container" "redis" {
  name  = "tf-redis"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.app.name
  }
}

# 4
resource "docker_image" "app" {
  name = "ghcr.io/dockersamples/example-voting-app-vote:latest"
}

# 5
resource "docker_container" "app" {
  name  = "tf-vote"
  image = docker_image.app.image_id

  env = [
    "REDIS_HOST=tf-redis",       # 6
  ]

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app.name
  }

  depends_on = [docker_container.redis]    # 7
}
```

**Line-by-line:**

- **`# 1`** — A user-defined Docker network. Containers attached to the same network can reach each other by container name as DNS (Docker's built-in DNS).
- **`# 2`** — The Redis image.
- **`# 3`** — The Redis container. `networks_advanced { name = ... }` attaches it to our custom network. We don't expose Redis to the host (no `ports` block) — only the app needs to reach it.
- **`# 4`** — The voting app image, pulled from GitHub Container Registry.
- **`# 5`** — The app container.
- **`# 6`** — The app code expects a `REDIS_HOST` environment variable. We set it to `tf-redis` — the container name, which Docker's DNS resolves on the user network.
- **`# 7`** — Explicit `depends_on`. Even though Terraform sees no attribute reference between the containers, we want Redis to be started first. This handles the case where the app crashes if it can't reach Redis at startup.

```bash
terraform apply -auto-approve
open http://localhost:8080
# Vote between cats and dogs!
terraform destroy -auto-approve
```

## 8.4 Refactoring into a module

If you're going to deploy this pattern 5 times with different images and configs, **extract a module**:

```
tf-docker-demo/
├── main.tf                # uses the module
├── versions.tf
└── modules/
    └── containerized-app/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

`modules/containerized-app/versions.tf`:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
```

`modules/containerized-app/variables.tf`:

```hcl
variable "name"         { type = string }
variable "image"        { type = string }
variable "external_port" {
  type    = number
  default = null              # null = don't expose externally
}
variable "env" {
  type    = map(string)
  default = {}
}
variable "network_name" { type = string }
```

`modules/containerized-app/main.tf`:

```hcl
resource "docker_image" "this" {
  name = var.image
}

resource "docker_container" "this" {
  name  = var.name
  image = docker_image.this.image_id

  env = [for k, v in var.env : "${k}=${v}"]    # 1

  # 2
  dynamic "ports" {
    for_each = var.external_port != null ? [1] : []
    content {
      internal = 80
      external = var.external_port
    }
  }

  networks_advanced {
    name = var.network_name
  }
}
```

**Notes:**

- **`# 1`** — Convert a map to a list of `KEY=VALUE` strings using a `for` expression. `for k, v in map : <expression>` iterates over key-value pairs.
- **`# 2`** — `dynamic "ports"` only generates the block if `external_port` is not null. This is the pattern for optional nested blocks.

`modules/containerized-app/outputs.tf`:

```hcl
output "name" {
  value = docker_container.this.name
}

output "url" {
  value = var.external_port != null ? "http://localhost:${var.external_port}" : null
}
```

Root `main.tf` becomes:

```hcl
resource "docker_network" "app" {
  name = "tf-app-net"
}

module "redis" {
  source       = "./modules/containerized-app"
  name         = "tf-redis"
  image        = "redis:7-alpine"
  network_name = docker_network.app.name
  # no external_port — internal only
}

module "vote" {
  source        = "./modules/containerized-app"
  name          = "tf-vote"
  image         = "ghcr.io/dockersamples/example-voting-app-vote:latest"
  external_port = 8080
  network_name  = docker_network.app.name
  env           = { REDIS_HOST = module.redis.name }
}

output "vote_url" {
  value = module.vote.url
}
```

This is the same pattern at every scale — only the resources change.

---

# 9. AWS Basics — Annotated

This section assumes you've set up the AWS CLI (§3.3). We'll build a VPC, then add an EC2 instance, then an S3 bucket, then RDS.

## 9.1 Authentication recap

Before every apply, verify which credentials Terraform will use:

```bash
echo $AWS_PROFILE          # ensure it's set
aws sts get-caller-identity
# Returns the IAM identity Terraform will assume
```

## 9.2 Foundational VPC — step by step

> **📚 Background — what a VPC is:** A VPC ("Virtual Private Cloud") is your isolated network inside AWS. Inside it you carve out **subnets** in different **Availability Zones**. Subnets are either **public** (have a route to an internet gateway, can serve traffic from the internet) or **private** (no internet ingress; can egress through a NAT). Most production architectures have ≥ 2 subnets per AZ × 3 AZs = 6 subnets minimum, organized as 3 public + 3 private (sometimes 3 more "intra" or "database" subnets with no NAT).

> **🔗 References:**
> - AWS VPC documentation — https://docs.aws.amazon.com/vpc/latest/userguide/
> - VPC best practices — https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html

### Step 1: Project skeleton

```
network/
├── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

### Step 2: `versions.tf`

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # 1
  backend "s3" {
    bucket         = "mycompany-tf-state"
    key            = "platform/network/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "mycompany-tf-locks"
    encrypt        = true
  }
}

# 2
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — Backend config (covered in §5.3). Pre-created bucket and DynamoDB table.
- **`# 2`** — `default_tags` applies these tags to *every* resource that supports tagging, automatically. This is much cleaner than tagging each resource individually, and ensures consistency.

> **🔗 Reference:** Default tags — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging

### Step 3: `variables.tf`

```hcl
variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "project" {
  type    = string
  default = "platform"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
```

### Step 4: `main.tf`

Use the community VPC module. It's been battle-tested for years; don't reinvent it.

```hcl
# 1
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # 2
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# 3
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "${var.project}-${var.environment}"
  cidr = var.vpc_cidr

  # 4
  azs             = local.azs
  private_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 8)]
  intra_subnets   = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 16)]

  # 5
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  one_nat_gateway_per_az = var.environment == "prod"

  # 6
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 7
  enable_flow_log                      = var.environment == "prod"
  create_flow_log_cloudwatch_iam_role  = var.environment == "prod"
  create_flow_log_cloudwatch_log_group = var.environment == "prod"

  # 8
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
```

**Line-by-line:**

- **`# 1`** — Data source: ask AWS for the list of AZs available in this region. The filter excludes opt-in-only AZs (some newer regions have these).
- **`# 2`** — `slice(list, start, end)` takes the first 3 AZs. (Some regions have 6 AZs; we don't need them all.)
- **`# 3`** — Instantiate the community VPC module, pinned to `5.13.0`. Its docs are at https://github.com/terraform-aws-modules/terraform-aws-vpc.
- **`# 4`** — Compute subnet CIDRs from the VPC CIDR.
  - `cidrsubnet("10.0.0.0/16", 4, k)` with k=0,1,2 produces `10.0.0.0/20`, `10.0.16.0/20`, `10.0.32.0/20` — three private subnets.
  - Adding 8 to k produces `10.0.128.0/20`, `10.0.144.0/20`, `10.0.160.0/20` — three public subnets.
  - Adding 16 produces three "intra" subnets (no route to internet at all — perfect for databases).
- **`# 5`** — NAT Gateway configuration. **NAT Gateways cost ~$32/month each** and route private-subnet outbound traffic. For dev, one NAT shared across all AZs is fine. For prod, you want one per AZ — if the AZ with the single NAT goes down, all your private workloads lose internet.
- **`# 6`** — DNS support inside the VPC. You almost always want both enabled — services like EKS depend on them.
- **`# 7`** — VPC Flow Logs (network packet metadata) — useful for security incidents. Only enable in prod (they cost money).
- **`# 8`** — Tags that Kubernetes uses for ELB auto-discovery. Even if you don't use EKS today, these tags don't hurt.

### Step 5: `outputs.tf`

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "intra_subnet_ids" {
  value = module.vpc.intra_subnets
}

output "azs" {
  value = local.azs
}
```

### Step 6: `terraform.tfvars`

```hcl
environment = "dev"
```

### Step 7: Apply

```bash
cd network
terraform init        # downloads aws provider + vpc module
terraform plan        # review carefully — should show many resources
terraform apply       # type 'yes'
```

Inspect what got created:

```bash
terraform output
terraform state list | head
# module.vpc.aws_vpc.this[0]
# module.vpc.aws_subnet.private[0]
# module.vpc.aws_subnet.private[1]
# module.vpc.aws_subnet.private[2]
# module.vpc.aws_subnet.public[0]
# ...
```

## 9.3 Reading state from another module

Now you want to build something *on top* of this VPC. Other stacks read its outputs via `terraform_remote_state`:

```hcl
# 1
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "mycompany-tf-state"
    key    = "platform/network/terraform.tfstate"
    region = "eu-west-1"
  }
}

# 2
resource "aws_security_group" "db" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  # ...
}
```

**Line-by-line:**

- **`# 1`** — A data source that reads another Terraform state file. It needs the backend type and config to find the file.
- **`# 2`** — Reference outputs via `data.terraform_remote_state.<name>.outputs.<output_name>`.

This works, but the `config` block has to know exact backend details and gets repetitive. **Terragrunt's `dependency` blocks (§11) handle this much more cleanly.**

> **🔗 Reference:** `terraform_remote_state` — https://developer.hashicorp.com/terraform/language/state/remote-state-data

## 9.4 EC2 instance — modern best practices

```hcl
# 1
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2
resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4
resource "aws_iam_instance_profile" "ec2" {
  name = aws_iam_role.ec2.name
  role = aws_iam_role.ec2.name
}

# 5
resource "aws_security_group" "web" {
  name        = "${var.name}-web"
  description = "Web server traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # 7
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    region = var.region
  })

  # 8
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # 9
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = var.name }
}
```

**Line-by-line:**

- **`# 1`** — Find the latest Amazon Linux 2023 AMI. `most_recent = true` sorts by creation date.
- **`# 2`** — IAM role the instance will assume. The `assume_role_policy` is the *trust policy* — it specifies who can assume the role. Here: EC2 itself (`Service = "ec2.amazonaws.com"`).
- **`# 3`** — Attach the AWS-managed SSM policy. This is the **modern way to access EC2 instances**: no SSH key, no public IP, no bastion. You connect via `aws ssm start-session --target i-...`.
- **`# 4`** — An "instance profile" — a container for an IAM role that you can attach to an EC2 instance. (Historical wart of AWS — roles and instance profiles are *almost* the same thing.)
- **`# 5`** — Security group: AWS's stateful firewall for the instance. Allow 443 in; allow all out. **Note we are NOT opening port 22** — see the gotcha below.
- **`# 6`** — The EC2 instance itself, wired up with all the above.
- **`# 7`** — `user_data` is a script that runs once when the instance first boots. We use `templatefile()` to render a template, substituting variables.
- **`# 8`** — **Force IMDSv2 only.** IMDS (Instance Metadata Service) is how an instance reads its own credentials and metadata. IMDSv1 had a SSRF vulnerability that led to the Capital One breach in 2019. Always require v2 (`http_tokens = "required"`).
- **`# 9`** — Encrypted gp3 root volume. gp3 is the modern AWS general-purpose SSD; cheaper than gp2 with better baseline performance. Always encrypt.

> **⚠️ Gotcha — don't open port 22:** SSH is a 30-year-old protocol with notorious attack surface. The modern AWS pattern is **SSM Session Manager**:
>
> ```bash
> aws ssm start-session --target i-0123456789abcdef0
> ```
>
> This gives you a shell on the instance with no public IP, no SSH key distribution, full audit logs in CloudTrail, and IAM-based access control. The `AmazonSSMManagedInstanceCore` policy is what makes this work.

User-data template `user-data.sh.tftpl`:

```bash
#!/bin/bash
# 1
set -euo pipefail

# 2
dnf update -y
dnf install -y nginx

# 3
systemctl enable --now nginx

# 4
echo "<html><body><h1>Hello from ${region}</h1></body></html>" > /usr/share/nginx/html/index.html
```

- **`# 1`** — Bash strict mode: exit on error, undefined vars, pipefail.
- **`# 2`** — AL2023 uses `dnf` (not `yum`).
- **`# 3`** — `systemctl enable --now` starts the service immediately AND enables it on boot.
- **`# 4`** — The `${region}` placeholder is substituted by `templatefile()` at plan time.

> **🔗 References:**
> - `aws_instance` resource — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
> - SSM Session Manager — https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html
> - IMDSv2 — https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html

## 9.5 S3 bucket — hardened defaults

We saw the bones in §7.5. Here's a fuller production version:

```hcl
# 1
resource "random_id" "suffix" {
  byte_length = 4
}

# 2
resource "aws_s3_bucket" "data" {
  bucket        = "${var.name}-${random_id.suffix.hex}"
  force_destroy = var.environment != "prod"

  lifecycle {
    prevent_destroy = false   # set to true on prod buckets you care about
  }
}

# 3
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 4
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# 5
resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 6
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "transition-archive-prefix"
    status = "Enabled"
    filter { prefix = "archive/" }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
```

**Key points:**

- **`# 1-2`** — Unique bucket names. S3 names are global; tack on a random suffix to avoid collisions.
- **`# 3`** — Versioning is configured separately from the bucket. Every prod bucket should have versioning enabled.
- **`# 4`** — Encryption at rest. `bucket_key_enabled = true` reduces KMS request costs when you upgrade to SSE-KMS.
- **`# 5`** — Block all forms of public access. The 4 flags are belt-and-suspenders.
- **`# 6`** — Lifecycle rules: expire old non-current versions after 90 days; transition data under `archive/` to cheaper storage classes.

> **🔗 References:**
> - `aws_s3_bucket` resource — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
> - S3 storage classes — https://aws.amazon.com/s3/storage-classes/

## 9.6 RDS PostgreSQL

```hcl
# 1
resource "random_password" "db" {
  length  = 32
  special = false
}

# 2
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.name}-db-password"
  description = "Master password for ${var.name} RDS"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

# 3
resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
}

# 4
resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "PostgreSQL access"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from app SGs"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }
}

# 5
resource "aws_db_instance" "this" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = var.instance_class
  allocated_storage       = 50
  max_allocated_storage   = 500
  storage_type            = "gp3"
  storage_encrypted       = true

  db_name                 = "appdb"
  username                = "appuser"
  password                = random_password.db.result

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false

  # 6
  multi_az                = var.environment == "prod"
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  # 7
  deletion_protection     = var.environment == "prod"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.name}-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}" : null

  # 8
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  # 9
  enabled_cloudwatch_logs_exports = ["postgresql"]

  lifecycle {
    ignore_changes = [final_snapshot_identifier]   # contains timestamp
  }
}
```

**Key points:**

- **`# 1`** — Generate a random password; never hardcode.
- **`# 2`** — Store it in AWS Secrets Manager so apps can fetch it at runtime.
- **`# 3`** — DB subnet group: RDS requires a list of subnets in ≥ 2 AZs.
- **`# 4`** — Security group: allow port 5432 only from specified SGs (e.g., the app SG). No CIDR ingress.
- **`# 5`** — The DB instance itself.
- **`# 6`** — Multi-AZ in prod (~2x cost; synchronous standby in another AZ).
- **`# 7`** — Production safeguards: deletion protection on, final snapshot on destroy.
- **`# 8`** — Performance Insights + enhanced monitoring.
- **`# 9`** — Ship Postgres logs to CloudWatch.

> **🔗 References:**
> - `aws_db_instance` resource — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
> - RDS best practices — https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html
> - Community RDS module (recommended) — https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest

---

# 10. Azure Basics — Annotated

## 10.1 Authentication

```bash
az login
az account list -o table
az account set --subscription "<sub-id>"
```

The `azurerm` provider picks up CLI credentials automatically. For CI, use OIDC federation (preferred) or a service principal.

```hcl
provider "azurerm" {
  features {}        # required even if empty

  # 1
  use_oidc        = true
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
}
```

- **`# 1`** — OIDC federation. No client secret needed; GitHub/GitLab/etc. provides an OIDC token that Azure trusts. Setup is on the Azure side: create an "App Registration" with federated credentials pointing at your CI repo.

> **🔗 References:**
> - AzureRM provider docs — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
> - Authentication via OIDC — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc

## 10.2 Resource group, VNet, subnets

> **📚 Background:** Azure organizes everything inside **resource groups** (logical containers, no equivalent in AWS). VNet ≈ AWS VPC. Subnets are simpler in Azure — no public/private distinction at the subnet level; routing controls that.

```hcl
# 1
resource "azurerm_resource_group" "main" {
  name     = "${var.name}-rg"
  location = var.location
  tags     = local.common_tags
}

# 2
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_cidr]
}

# 3
locals {
  zones = ["1", "2", "3"]
}

# 4
resource "azurerm_subnet" "private" {
  for_each             = toset(local.zones)
  name                 = "private-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, tonumber(each.key) - 1)]
}

resource "azurerm_subnet" "public" {
  for_each             = toset(local.zones)
  name                 = "public-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, tonumber(each.key) - 1 + 8)]
}
```

**Key points:**

- **`# 1`** — Resource groups contain *everything* in Azure. Each resource belongs to exactly one RG.
- **`# 2`** — VNet is the equivalent of VPC. Note: `address_space` is a list (Azure supports multiple non-contiguous ranges per VNet).
- **`# 3`** — Azure uses **availability zones** numbered 1/2/3 within a region.
- **`# 4`** — Three subnets, one per AZ, computed from the VNet CIDR.

> **🔗 References:**
> - `azurerm_virtual_network` — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
> - Azure VNet docs — https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview

## 10.3 Linux VM

```hcl
# 1
resource "azurerm_public_ip" "vm" {
  name                = "${var.name}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

# 2
resource "azurerm_network_interface" "vm" {
  name                = "${var.name}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public["1"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# 3
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.vm.id]
  zone                  = "1"

  # 4
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # 5
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # 6
  identity {
    type = "SystemAssigned"
  }
}
```

**Notes:**

- **`# 1`** — Public IPs in Azure are *resources*, not attributes of VMs. `Standard` SKU + zone is the modern recommendation.
- **`# 2`** — NICs are also resources. Attach them to subnets and optionally to public IPs.
- **`# 3`** — The VM itself. `size` is Azure's instance type code.
- **`# 4`** — SSH key auth. Azure doesn't have a built-in "key pair" object — you just upload the public key inline.
- **`# 5`** — Image reference: publisher (Canonical) / offer (Ubuntu Server) / SKU (version family) / version.
- **`# 6`** — Managed Identity — Azure's equivalent of IAM roles for instances. Lets the VM authenticate to other Azure services without storing credentials.

> **🔗 References:**
> - `azurerm_linux_virtual_machine` — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
> - Managed Identity overview — https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview

## 10.4 Storage account + blob container

```hcl
resource "azurerm_storage_account" "main" {
  name                      = lower(replace("${var.name}sa", "-", ""))   # 3-24 chars, alphanumeric
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"               # Geo-redundant storage
  min_tls_version           = "TLS1_2"
  shared_access_key_enabled = false               # force AAD auth
  https_traffic_only_enabled = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
```

> **🔗 Reference:** Storage account docs — https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account

---

# 11. Terragrunt — The Why and the How

## 11.1 The problem Terragrunt solves — illustrated

Imagine a realistic enterprise layout:

```
live/
├── prod/
│   ├── eu-west-1/
│   │   ├── network/
│   │   ├── eks/
│   │   ├── rds/
│   │   └── kafka/
│   └── us-east-1/
│       └── (same 4 components)
├── staging/
│   └── eu-west-1/ (same 4 components)
└── dev/
    └── eu-west-1/ (same 4 components)
```

That's **16 Terraform projects**. With plain Terraform, each leaf needs:

- a `terraform { backend "s3" { ... } }` block with a unique `key`
- a `provider "aws" { region = ... }` block
- variables for region, environment, account ID, etc.

If you change the state bucket name, you edit 16 files. Set up a new region? 4 more directories of boilerplate. Add an `assume_role` for the Terraform IAM role? 16 edits.

**Terragrunt eliminates this boilerplate** by inheriting config down the directory tree.

## 11.2 The `terragrunt.hcl` file — line by line

Terragrunt walks up the directory tree looking for `terragrunt.hcl` files, then merges them.

### Root `terragrunt.hcl` — defined once at `live/terragrunt.hcl`

```hcl
# 1
locals {
  # 2
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # 3
  account_id   = local.account_vars.locals.aws_account_id
  account_name = local.account_vars.locals.account_name
  region       = local.region_vars.locals.aws_region
  environment  = local.environment_vars.locals.environment
}

# 4
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "mycompany-tf-state-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "mycompany-tf-locks"
  }
}

# 5
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.region}"
  allowed_account_ids = ["${local.account_id}"]

  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
      Account     = "${local.account_name}"
    }
  }
}
EOF
}

# 6
inputs = {
  environment  = local.environment
  region       = local.region
  account_id   = local.account_id
  account_name = local.account_name
}
```

**Line-by-line:**

- **`# 1`** — A `locals` block. Same idea as Terraform locals but Terragrunt-scoped.
- **`# 2`** — `read_terragrunt_config(path)` parses another HCL file and returns its contents. `find_in_parent_folders("account.hcl")` walks up the tree looking for an `account.hcl` file. The combination lets each environment define its own values in dedicated files.
- **`# 3`** — Pull values out of those config files.
- **`# 4`** — `remote_state` configures the backend Terragrunt **generates on the fly**. The `generate` block tells Terragrunt to write a `backend.tf` file into the Terraform working directory. `path_relative_to_include()` produces a path like `prod/eu-west-1/eks` — so the S3 key becomes `prod/eu-west-1/eks/terraform.tfstate`, unique per component.
- **`# 5`** — Similar generation for the AWS provider. The provider block ends up in the Terraform working directory at apply time, with values interpolated.
- **`# 6`** — `inputs = {...}` is passed as Terraform variables to every child module that includes this root config.

### Per-environment file: `live/prod/account.hcl`

```hcl
locals {
  aws_account_id = "111122223333"
  account_name   = "prod"
}
```

### Per-environment file: `live/prod/env.hcl`

```hcl
locals {
  environment = "prod"
}
```

### Per-region file: `live/prod/eu-west-1/region.hcl`

```hcl
locals {
  aws_region = "eu-west-1"
}
```

### Leaf file: `live/prod/eu-west-1/network/terragrunt.hcl`

```hcl
# 1
include "root" {
  path = find_in_parent_folders()
}

# 2
terraform {
  source = "git::https://github.com/mycompany/tf-modules.git//vpc?ref=v1.4.0"
}

# 3
inputs = {
  vpc_cidr = "10.10.0.0/16"
  project  = "platform"
}
```

**Line-by-line:**

- **`# 1`** — `include "root" { path = find_in_parent_folders() }` — the magic. Walks up directories until it finds another `terragrunt.hcl` (in `live/`) and inherits all of its settings: backend, provider, locals, inputs.
- **`# 2`** — `terraform { source = ... }` — where the actual Terraform code lives. Terragrunt downloads the module (or uses a local path) into a cache directory and runs Terraform there.
- **`# 3`** — Inputs *specific* to this leaf. They merge with the inputs from the root.

That's the whole leaf file. 12 lines, all the logic in two reusable layers.

> **🔗 References:**
> - `terragrunt.hcl` reference — https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/
> - Built-in functions like `find_in_parent_folders`, `path_relative_to_include` — https://terragrunt.gruntwork.io/docs/reference/built-in-functions/
> - Keeping your code DRY — https://terragrunt.gruntwork.io/docs/features/keep-your-terraform-code-dry/

## 11.3 Running Terragrunt

```bash
cd live/prod/eu-west-1/network
terragrunt init      # downloads module, configures backend
terragrunt plan      # generates files, runs terraform plan
terragrunt apply     # generates files, runs terraform apply
```

Under the hood, when you run `terragrunt apply` in that directory:

1. Terragrunt finds your `terragrunt.hcl`.
2. Walks up the tree, merging all parent `terragrunt.hcl` files.
3. Downloads the module (`tf-modules.git//vpc?ref=v1.4.0`) into `.terragrunt-cache/.../vpc/`.
4. Generates `backend.tf` and `provider.tf` inside that cache directory.
5. Runs `terraform init` to configure the backend.
6. Runs `terraform apply` with all your inputs.

## 11.4 Cross-module dependencies

> **📚 Background:** This is Terragrunt's killer feature. In layered architectures, the EKS module needs the VPC's outputs. Plain Terraform: use `terraform_remote_state` data sources (verbose). Terragrunt: `dependency` blocks (clean).

`live/prod/eu-west-1/eks/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/mycompany/tf-modules.git//eks?ref=v2.1.0"
}

# 1
dependency "network" {
  config_path = "../network"

  # 2
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

inputs = {
  cluster_name = "platform-prod"

  # 3
  vpc_id       = dependency.network.outputs.vpc_id
  subnet_ids   = dependency.network.outputs.private_subnet_ids
}
```

**Line-by-line:**

- **`# 1`** — Declare a dependency on the network module by relative path. Terragrunt will:
  1. Run `terragrunt output` against the network module to fetch its current outputs.
  2. Make those outputs available as `dependency.network.outputs.*`.
  3. If the network module hasn't been applied yet (no state), use the mock outputs (see below).
  4. With `terragrunt run --all apply`, automatically apply network *before* this module.
- **`# 2`** — Mock outputs. When you run `terragrunt plan` in the EKS module *before* the network has been applied, real outputs don't exist yet. Mocks let `plan` succeed for review. `mock_outputs_allowed_terraform_commands` restricts when mocks are used — never for `apply` (you'd apply with mock IDs and break things).
- **`# 3`** — Reference dependency outputs. Type-safely passed as inputs to Terraform.

> **🔗 Reference:** Dependencies in Terragrunt — https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#dependencies-between-modules

## 11.5 Running many modules at once

```bash
# 1 — Newer Terragrunt syntax (0.60+)
terragrunt run --all plan
terragrunt run --all apply --non-interactive

# 2 — Older syntax (still works)
terragrunt run-all plan
terragrunt run-all apply --terragrunt-non-interactive

# 3 — Apply only a subset (and their dependencies)
terragrunt run --all apply --queue-include-dir=eks
```

**Notes:**

- **`# 1`** — From the root of `live/prod/eu-west-1/`, this plans/applies *every* component in dependency order, parallelizing where it can.
- **`# 2`** — Older command name; same behavior. Both are supported in modern Terragrunt.
- **`# 3`** — Apply just the EKS module, and any of its dependencies that aren't already up-to-date.

> **⚠️ Gotcha:** `run --all apply --non-interactive` is extremely powerful and equally dangerous. Use it in CI with strict guardrails. In interactive use, **always do `run --all plan` first** and read every component's plan before applying.

## 11.6 Useful Terragrunt features

### Hook scripts

```hcl
terraform {
  before_hook "format" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "fmt", "-recursive"]
  }

  after_hook "notify" {
    commands     = ["apply"]
    execute      = ["./scripts/notify-slack.sh"]
    run_on_error = false
  }
}
```

Run scripts before or after Terraform commands. Useful for formatting, notifications, generating reports.

### Extra arguments

```hcl
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_parent_terragrunt_dir()}/common.tfvars",
      "${get_terragrunt_dir()}/env.tfvars",
    ]
  }
}
```

`extra_arguments` injects additional CLI flags into Terraform calls. Common use: auto-load `.tfvars` files from specific paths.

### Skip a module

```hcl
skip = true
```

Useful for "this is a deprecated component, don't run it in `run --all`."

### Prevent destroy

```hcl
prevent_destroy = true
```

Terragrunt will refuse to run `destroy` on this module.

> **🔗 References:**
> - Hooks — https://terragrunt.gruntwork.io/docs/features/hooks/
> - Built-in functions reference — https://terragrunt.gruntwork.io/docs/reference/built-in-functions/

## 11.7 Reading external config files

If non-engineers need to set values, YAML is easier than HCL:

```hcl
locals {
  global  = yamldecode(file("${get_parent_terragrunt_dir()}/global.yml"))
  env_cfg = yamldecode(file("${get_terragrunt_dir()}/../env.yml"))
}
```

Now SREs and PMs can update `global.yml` without touching HCL.

---

# 12. Layered Architecture for Teams

## 12.1 Recommended repository layout

```
infrastructure/
├── modules/                          # versioned, reusable Terraform modules
│   ├── vpc/
│   ├── eks/
│   ├── eks-addons/
│   ├── rds-postgres/
│   ├── s3-bucket/
│   ├── ecs-service/
│   ├── kafka-msk/
│   ├── opensearch/
│   ├── alb/
│   └── observability-stack/
│
├── live/                             # actual deployed configurations (Terragrunt)
│   ├── terragrunt.hcl                # global root config (backend, provider)
│   ├── _envcommon/                   # per-component shared inputs
│   │   ├── vpc.hcl
│   │   ├── eks.hcl
│   │   └── ...
│   │
│   ├── prod/
│   │   ├── account.hcl               # AWS account ID, etc.
│   │   ├── env.hcl                   # environment="prod"
│   │   ├── eu-west-1/
│   │   │   ├── region.hcl
│   │   │   ├── 10-network/
│   │   │   ├── 20-shared-services/
│   │   │   ├── 30-eks/
│   │   │   ├── 40-data-rds/
│   │   │   ├── 50-data-kafka/
│   │   │   ├── 60-observability/
│   │   │   └── 70-apps/
│   │   │       ├── service-a/
│   │   │       └── service-b/
│   │   └── us-east-1/                # disaster recovery region
│   │
│   ├── staging/
│   └── dev/
│
├── policies/                         # OPA / Sentinel policies
├── .github/workflows/                # CI/CD
└── README.md
```

**Notes on the layout:**

- **Numeric prefixes (`10-`, `20-`, `30-`)** suggest deployment order to humans. Terragrunt's `dependency` blocks enforce it programmatically.
- **`_envcommon/`** — the underscore prefix keeps it out of `run --all` (Terragrunt skips folders starting with `_`).
- **One account per top-level env folder** is convenient when you use separate AWS accounts per environment (the industry best practice).

## 12.2 The `_envcommon` pattern

When the same component is deployed in 3 envs × 2 regions = 6 places, share inputs via `_envcommon`:

`live/_envcommon/vpc.hcl`:

```hcl
# 1
terraform {
  source = "git::https://github.com/mycompany/tf-modules.git//vpc?ref=v1.4.0"
}

# 2
inputs = {
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

`live/prod/eu-west-1/10-network/terragrunt.hcl`:

```hcl
# 3
include "root" {
  path = find_in_parent_folders()
}

# 4
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/vpc.hcl"
}

# 5
inputs = {
  vpc_cidr               = "10.10.0.0/16"
  single_nat_gateway     = false   # prod gets one NAT per AZ
  one_nat_gateway_per_az = true
}
```

`live/dev/eu-west-1/10-network/terragrunt.hcl`:

```hcl
include "root"     { path = find_in_parent_folders() }
include "envcommon" { path = "${dirname(find_in_parent_folders())}/_envcommon/vpc.hcl" }

inputs = {
  vpc_cidr           = "10.30.0.0/16"
  single_nat_gateway = true   # dev saves money with one shared NAT
}
```

**The pattern:**

- `_envcommon/vpc.hcl` holds settings *common to all environments* (which module version, which features enabled).
- Each leaf `terragrunt.hcl` adds environment-specific *overrides* (CIDR, NAT topology).

The difference between dev and prod is now literally **a CIDR and a NAT flag** — exactly what should differ.

> **🔗 Reference:** envcommon pattern — https://terragrunt.gruntwork.io/docs/features/keep-your-terraform-code-dry/#dry-common-terraform-code-with-terragrunt-generate-blocks

## 12.3 Cross-account, cross-region patterns

Real AWS organizations have multiple accounts (typically: org-management, security-audit, log-archive, shared-services, dev, staging, prod). Terragrunt makes this clean by generating a different provider per directory.

Excerpt from `live/terragrunt.hcl`:

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.region}"
  allowed_account_ids = ["${local.account_id}"]

  assume_role {
    role_arn     = "arn:aws:iam::${local.account_id}:role/TerraformExecutionRole"
    session_name = "terragrunt-$${replace(get_aws_account_id(),"-","")}"
  }

  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}
```

**How it works:**

- Each environment folder has its own `account.hcl` with the account ID.
- The generated provider assumes a role in that account.
- `allowed_account_ids` is a safety check: Terraform refuses to talk to any other account, even if credentials would let it.

Your humans login once to the org-management account via SSO; Terragrunt hops into the appropriate target account per directory.

## 12.4 Promoting changes between environments

Workflow for shipping a new feature in a shared module:

1. **Developer creates a branch** in the `tf-modules` repo (or a single monorepo).
2. **Modifies `modules/foo/`** — adds a feature, fixes a bug.
3. **Tags a release**: `git tag foo/v1.5.0 && git push --tags`.
4. **In the `live/` repo**, edits `live/dev/.../foo/terragrunt.hcl` to point `?ref=foo/v1.5.0`.
5. **CI runs `terragrunt plan`** on the PR. Reviewer sees what would change.
6. **PR merged** → CI applies to dev.
7. **After validation**, a follow-up PR bumps `?ref=` in `live/staging/...`, then `live/prod/...`.

The version pin in `?ref=` is your **promotion gate**. Dev runs ahead, prod stays on what's been proven.

This is the *infrastructure equivalent* of "lower environments run beta versions, prod runs stable releases" — and it works exactly like normal software dependency management.

---

```hcl
# 1
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# 2
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# 3
resource "aws_iam_role" "task_execution" {
  name = "${var.name}-task-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4
resource "aws_iam_role" "task" {
  name = "${var.name}-task"
  assume_role_policy = aws_iam_role.task_execution.assume_role_policy
}

# 5
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

# 6
resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"     # 0.5 vCPU
  memory                   = "1024"    # 1 GiB
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.image
      essential = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]

      environment = [for k, v in var.env : { name = k, value = v }]

      # 7
      secrets = [for k, arn in var.secrets : {
        name      = k
        valueFrom = arn
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])
}

# 8
resource "aws_security_group" "service" {
  name   = "${var.name}-svc"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 9
resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = 8080
  }

  # 10
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller { type = "ECS" }

  lifecycle {
    ignore_changes = [desired_count]   # autoscaling manages it
  }
}

# 11 — Application Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 20
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
```

**Line-by-line:**

- **`# 1`** — The ECS cluster — a logical grouping. Container Insights enables detailed CloudWatch metrics for tasks/services.
- **`# 2`** — Tell the cluster which capacity providers (FARGATE for on-demand, FARGATE_SPOT for ~70% cheaper spot). The default strategy says "always run at least 1 on FARGATE."
- **`# 3`** — The **task execution role** — used by ECS itself to pull images and write logs. NOT the role your app code runs as.
- **`# 4`** — The **task role** — what your application code uses to call other AWS APIs (S3, DynamoDB, etc.). This is the role to attach least-privilege policies to.
- **`# 5`** — Log group for container output. 30-day retention; adjust by policy.
- **`# 6`** — Task definition: a versioned blueprint. CPU/memory are predefined Fargate combos (see [Fargate sizes](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-defs.html#fargate-tasks-size)).
- **`# 7`** — Secrets pulled from Secrets Manager or SSM Parameter Store at task start — never baked into env vars or images.
- **`# 8`** — Security group: only the ALB's SG can reach the service port. No 0.0.0.0/0 ingress.
- **`# 9`** — The ECS service: declares "I want 3 copies of this task running, registered behind this target group."
- **`# 10`** — Circuit breaker: if deployments fail health checks, ECS automatically rolls back. Always enable.
- **`# 11`** — Autoscaling: 2–20 tasks targeting 60% CPU.

> **🔗 References:**
> - `aws_ecs_service` — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
> - ECS task definition reference — https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
> - Community ECS modules — https://github.com/terraform-aws-modules/terraform-aws-ecs

## 15.2 ECS vs EKS — when to choose what

| Use ECS Fargate when…                              | Use EKS when…                                          |
| -------------------------------------------------- | ------------------------------------------------------ |
| AWS is your only cloud                             | You need portability or multi-cloud                    |
| Team is small / not K8s-experienced                | Team already knows Kubernetes                          |
| Workload is < ~50 microservices                    | Many teams, many services, complex topologies          |
| You want minimal ops                               | You want rich ecosystem (Istio, Argo, Operators)       |
| Cost optimization through Fargate Spot is enough   | You need granular cost optimization via node packing   |

Default answer for new teams in AWS: **ECS Fargate.** Default for K8s shops: **EKS.**

---

# 16. Ansible Integration

## 16.1 Background — where Terraform stops and Ansible begins

> **📚 Background:** These two tools solve complementary problems:
>
> - **Terraform** declares *that resources exist*: VMs, networks, load balancers, DNS records. It's at its best when describing the **shape** of infrastructure.
> - **Ansible** configures *what's inside resources*: install nginx, render config files, restart services, apply OS patches. It's at its best for **state inside a running OS**.
>
> You *can* do configuration management with Terraform (`user_data`, `cloud-init`, `remote-exec`), but it gets ugly past a few lines of bash. You *can* do provisioning with Ansible (the [`amazon.aws`](https://docs.ansible.com/ansible/latest/collections/amazon/aws/index.html) collection), but the drift detection model is much weaker than Terraform's.
>
> The clean separation:
>
> ```
> Terraform   ── creates ──>   VMs, IPs, DNS, security groups
>                                 │
>                                 │ Ansible reads inventory
>                                 ▼
> Ansible     ── configures ──>  Software inside those VMs
> ```

> **🔗 References:**
> - Ansible docs — https://docs.ansible.com/
> - The Ansible amazon.aws collection — https://docs.ansible.com/ansible/latest/collections/amazon/aws/index.html
> - Best practices for Terraform + Ansible together — https://www.hashicorp.com/blog/terraform-without-the-bs

## 16.2 Generating an Ansible inventory from Terraform — option 1

Render an inventory file as a Terraform output:

`inventory.tf`:

```hcl
# 1
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    web_servers = [
      for instance in aws_instance.web : {
        name       = instance.tags["Name"]
        private_ip = instance.private_ip
      }
    ]
    db_servers = [
      for instance in aws_instance.db : {
        name       = instance.tags["Name"]
        private_ip = instance.private_ip
      }
    ]
  })
}
```

`templates/inventory.ini.tftpl`:

```ini
[web]
%{ for s in web_servers ~}
${s.name} ansible_host=${s.private_ip}
%{ endfor ~}

[db]
%{ for s in db_servers ~}
${s.name} ansible_host=${s.private_ip}
%{ endfor ~}

[all:vars]
ansible_user=ec2-user
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=22"'
```

**Notes:**

- The template directives `%{ for ... ~}` and `%{ endfor ~}` are Terraform's looping syntax inside templates. The `~` strips surrounding whitespace.
- The `ProxyCommand` uses **SSH over SSM** — no public IPs, no SSH keys distributed, full audit trail.

> **🔗 Reference:** SSH over SSM — https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-enable-ssh-connections.html

## 16.3 Dynamic inventory — option 2 (preferred)

Skip the templated file entirely. Use Ansible's AWS dynamic inventory plugin, which queries EC2 directly by tag.

`ansible.cfg`:

```ini
[defaults]
inventory = ./aws_ec2.yml
host_key_checking = False
```

`aws_ec2.yml`:

```yaml
plugin: amazon.aws.aws_ec2

# 1
regions:
  - eu-west-1

# 2
filters:
  tag:ManagedBy: terraform
  tag:Environment: prod
  instance-state-name: running

# 3
keyed_groups:
  - prefix: role
    key: tags.Role
  - prefix: env
    key: tags.Environment

# 4
hostnames:
  - tag:Name

# 5
compose:
  ansible_host: private_ip_address
```

**Line-by-line:**

- **`# 1`** — Which AWS regions to scan.
- **`# 2`** — Filter to instances Terraform manages. The `instance-state-name: running` keeps stopped instances out of inventory.
- **`# 3`** — Auto-group instances by their tags. With `prefix: role` + `key: tags.Role`, an instance tagged `Role=web` ends up in group `role_web`.
- **`# 4`** — Use the `Name` tag as the Ansible hostname (rather than the EC2 instance ID).
- **`# 5`** — Set `ansible_host` to the private IP (rather than DNS).

In your Terraform, tag instances consistently:

```hcl
tags = {
  Name        = "web-1"
  Role        = "web"
  Environment = "prod"
  ManagedBy   = "terraform"
}
```

Now Ansible:

```bash
ansible-inventory --graph
# @all:
#   |--@role_web:
#   |  |--web-1
#   |  |--web-2
#   |--@env_prod:
#   |  |--web-1
#   |  |--web-2

ansible role_web -m ping
ansible-playbook -i aws_ec2.yml site.yml
```

> **🔗 References:**
> - amazon.aws.aws_ec2 plugin — https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html
> - Dynamic inventory in general — https://docs.ansible.com/ansible/latest/inventory_guide/intro_dynamic_inventory.html

## 16.4 Calling Ansible from Terraform — last resort

For a "one button apply", you can have Terraform trigger Ansible:

```hcl
# 1
resource "null_resource" "ansible" {
  # 2
  triggers = {
    instance_ids = join(",", aws_instance.web[*].id)
    playbook_sha = filesha256("${path.module}/../ansible/site.yml")
  }

  # 3
  provisioner "local-exec" {
    command     = "ansible-playbook -i aws_ec2.yml site.yml"
    working_dir = "${path.module}/../ansible"
  }

  depends_on = [aws_instance.web]
}
```

**Why this is fragile:**

- **`# 1`** — `null_resource` is a no-op resource that exists only to run provisioners.
- **`# 2`** — The `triggers` map controls when this re-runs. If the instance list or the playbook hashes change, it re-runs.
- **`# 3`** — `local-exec` runs on the machine doing the apply — so it needs Ansible installed, AWS creds, and network access to the targets.

> **⚠️ Gotcha:** `local-exec` is a smell. It couples your Terraform runner with execution tooling. The cleaner pattern is two **separate CI stages**:
>
> ```
> stage: terraform-apply    → builds VMs
> stage: ansible-configure  → configures them
> ```

---

# 17. Complex Workloads

This section shows production-shaped data and streaming systems. Each subsection shows **two flavors**:

- **Managed** (AWS-native: MSK, OpenSearch Service) — less to operate.
- **Self-hosted on Kubernetes** — portable, more control, more ops.

## 17.1 Apache Kafka + Zookeeper

> **📚 Background:** [Kafka](https://kafka.apache.org/) is a distributed log-based message broker. Producers append messages to **topics**; topics are split into **partitions** (ordered, append-only logs) replicated across brokers. Consumers read at their own pace, tracking their position with offsets. Kafka is the de facto backbone of modern streaming architectures.
>
> Historically, Kafka required **Zookeeper** for cluster coordination (broker membership, leader election, config storage). Kafka 3.3+ supports **KRaft mode** which replaces Zookeeper with built-in Raft consensus. New clusters should use KRaft when possible.

> **🔗 References:**
> - Kafka documentation — https://kafka.apache.org/documentation/
> - KRaft mode overview — https://developer.confluent.io/learn/kraft/
> - The book *Designing Data-Intensive Applications* by Martin Kleppmann — https://dataintensive.net/
> - Confluent's Kafka tutorials — https://developer.confluent.io/tutorials/

### Option A: Amazon MSK (managed) — annotated

```hcl
# 1
resource "aws_security_group" "msk" {
  name   = "${var.name}-msk"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 9092
    to_port         = 9098
    protocol        = "tcp"
    security_groups = var.client_security_group_ids
    description     = "Kafka client ports (plain, TLS, IAM, SASL/SCRAM)"
  }
}

# 2
resource "aws_kms_key" "msk" {
  description             = "MSK encryption at rest"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# 3
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.name}"
  retention_in_days = 30
}

# 4
resource "aws_msk_configuration" "main" {
  name           = "${var.name}-config"
  kafka_versions = ["3.7.x"]

  server_properties = <<PROPERTIES
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.partitions=6
log.retention.hours=168
unclean.leader.election.enable=false
PROPERTIES
}

# 5
resource "aws_msk_cluster" "main" {
  cluster_name           = var.name
  kafka_version          = "3.7.x"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.private_subnet_ids
    security_groups = [aws_security_group.msk.id]
    storage_info {
      ebs_storage_info { volume_size = 100 }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  # 6
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  # 7
  client_authentication {
    sasl { iam = true }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  # 8
  open_monitoring {
    prometheus {
      jmx_exporter  { enabled_in_broker = true }
      node_exporter { enabled_in_broker = true }
    }
  }
}

output "bootstrap_brokers_sasl_iam" {
  value = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
}
```

**Line-by-line:**

- **`# 1`** — Security group allowing Kafka client ports (9092 plain, 9094 TLS, 9098 IAM, etc.) from approved client SGs only.
- **`# 2`** — KMS key for encryption at rest. Auto-rotated annually.
- **`# 3`** — CloudWatch log group for broker logs.
- **`# 4`** — MSK configuration: broker-side server properties. Notice the production defaults: replication 3, in-sync replicas 2, no auto topic creation, no unclean leader election.
- **`# 5`** — The cluster itself: 3 brokers, one per AZ in the provided subnets.
- **`# 6`** — Encryption at rest (KMS) and in transit (TLS between clients and brokers).
- **`# 7`** — IAM-based auth — no usernames/passwords. Clients authenticate as IAM principals.
- **`# 8`** — Prometheus-scrapable JMX metrics for free. Point your Prometheus at `b-1.<cluster>.kafka.<region>.amazonaws.com:11001` etc.

> **🔗 References:**
> - MSK documentation — https://docs.aws.amazon.com/msk/
> - `aws_msk_cluster` — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster

### Option B: Self-hosted Kafka on Kubernetes via Strimzi

[Strimzi](https://strimzi.io/) is the de facto Kubernetes operator for Kafka.

```hcl
# 1
resource "helm_release" "strimzi_operator" {
  name             = "strimzi-kafka-operator"
  namespace        = "kafka"
  repository       = "https://strimzi.io/charts/"
  chart            = "strimzi-kafka-operator"
  version          = "0.43.0"
  create_namespace = true
}

# 2
resource "kubernetes_manifest" "kafka_cluster" {
  manifest = yamldecode(<<-YAML
    apiVersion: kafka.strimzi.io/v1beta2
    kind: Kafka
    metadata:
      name: prod
      namespace: kafka
    spec:
      kafka:
        version: 3.7.0
        replicas: 3
        listeners:
          - name: plain
            port: 9092
            type: internal
            tls: false
          - name: tls
            port: 9093
            type: internal
            tls: true
          - name: external
            port: 9094
            type: loadbalancer
            tls: true
        config:
          offsets.topic.replication.factor: 3
          transaction.state.log.replication.factor: 3
          transaction.state.log.min.isr: 2
          default.replication.factor: 3
          min.insync.replicas: 2
          inter.broker.protocol.version: "3.7"
        storage:
          type: jbod
          volumes:
            - id: 0
              type: persistent-claim
              size: 100Gi
              deleteClaim: false
              class: gp3
        resources:
          requests: { memory: 4Gi, cpu: "1" }
          limits:   { memory: 4Gi, cpu: "2" }
      zookeeper:
        replicas: 3
        storage:
          type: persistent-claim
          size: 20Gi
          class: gp3
      entityOperator:
        topicOperator: {}
        userOperator: {}
      kafkaExporter:
        topicRegex: ".*"
        groupRegex: ".*"
  YAML
  )

  depends_on = [helm_release.strimzi_operator]
}
```

**Line-by-line:**

- **`# 1`** — Install the Strimzi operator into the `kafka` namespace. The operator watches for `Kafka` CRDs and reconciles them.
- **`# 2`** — Declare a Kafka cluster as a Kubernetes CRD via `kubernetes_manifest`. Strimzi creates StatefulSets, Services, ConfigMaps, PVCs etc. from this spec.
  - `listeners` — three different ways clients can connect: plain (internal, no TLS), TLS (internal, encrypted), external (LoadBalancer Service per broker, TLS-encrypted).
  - `storage: jbod` — multiple disks per broker. Here just one 100Gi gp3 volume.
  - `entityOperator` enables managing `KafkaTopic` and `KafkaUser` resources as CRDs (next snippet).
  - `kafkaExporter` deploys the Prometheus exporter for topic/consumer-group metrics.

> Note: For new clusters on Kafka 3.5+ you can use **KRaft mode** by setting `spec.kafka.kraft: true` and removing the `zookeeper` block. Strimzi 0.40+ supports this stably.

### Topics, users, ACLs — all as code

```hcl
resource "kubernetes_manifest" "topic_orders" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaTopic"
    metadata = {
      name      = "orders"
      namespace = "kafka"
      labels    = { "strimzi.io/cluster" = "prod" }
    }
    spec = {
      partitions = 12
      replicas   = 3
      config = {
        "retention.ms"        = "604800000"      # 7 days
        "segment.bytes"       = "1073741824"     # 1 GiB
        "min.insync.replicas" = "2"
      }
    }
  }
}

resource "kubernetes_manifest" "user_billing" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaUser"
    metadata = {
      name      = "billing-svc"
      namespace = "kafka"
      labels    = { "strimzi.io/cluster" = "prod" }
    }
    spec = {
      authentication = { type = "scram-sha-512" }
      authorization = {
        type = "simple"
        acls = [
          {
            resource    = { type = "topic", name = "orders", patternType = "literal" }
            operations  = ["Read", "Describe"]
          },
          {
            resource    = { type = "group", name = "billing-", patternType = "prefix" }
            operations  = ["Read"]
          }
        ]
      }
    }
  }
}
```

Strimzi creates a Kubernetes Secret with the user's SASL password. Pair with [External Secrets Operator](https://external-secrets.io/) to sync to AWS Secrets Manager or Azure Key Vault.

> **🔗 References:**
> - Strimzi docs — https://strimzi.io/documentation/
> - Strimzi Kafka tutorial — https://strimzi.io/docs/operators/latest/quickstart.html
> - Confluent's free Kafka course — https://developer.confluent.io/learn-kafka/

## 17.2 Apache NiFi

> **📚 Background:** [NiFi](https://nifi.apache.org/) is a dataflow / ETL tool — drag-and-drop data pipelines with backpressure, provenance tracking, lineage, and clustering. Common uses: ingest from many sources (FTP, MQTT, REST, files), transform/enrich, route to sinks (S3, Kafka, databases). Production NiFi runs clustered with Zookeeper coordination.

```hcl
resource "helm_release" "nifi" {
  name             = "nifi"
  namespace        = "nifi"
  repository       = "https://cetic.github.io/helm-charts"
  chart            = "nifi"
  version          = "1.2.1"
  create_namespace = true

  values = [yamlencode({
    # 1
    replicaCount = 3

    # 2
    properties = {
      isNode              = true
      httpsPort           = 8443
      clusterPort         = 6007
      provenanceStorage   = "32 GB"
      sensitiveKey        = var.sensitive_key   # from a secret in real use
      webProxyHost        = "nifi.prod.example.com:443"
    }

    # 3
    auth = {
      admin = "CN=admin, OU=NIFI"
      ldap  = { enabled = false }
      oidc = {
        enabled              = true
        discoveryUrl         = "https://login.example.com/.well-known/openid-configuration"
        clientId             = var.oidc_client_id
        clientSecret         = var.oidc_client_secret
        claimIdentifyingUser = "email"
      }
    }

    # 4
    zookeeper = {
      enabled      = true
      replicaCount = 3
    }

    # 5
    persistence = {
      enabled               = true
      storageClass          = "gp3"
      dataStorage           = { size = "50Gi" }
      flowfileRepoStorage   = { size = "20Gi" }
      contentRepoStorage    = { size = "100Gi" }
      provenanceRepoStorage = { size = "50Gi" }
    }

    # 6
    service = { type = "ClusterIP" }
    ingress = {
      enabled          = true
      ingressClassName = "alb"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"       = "internal"
        "alb.ingress.kubernetes.io/target-type"  = "ip"
        "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\": 443}]"
      }
      hosts = [{ host = "nifi.prod.example.com" }]
    }

    # 7
    metrics = {
      prometheus = { enabled = true }
    }
  })]
}
```

**Line-by-line:**

- **`# 1`** — Three nodes for HA. NiFi uses quorum-based coordination via Zookeeper.
- **`# 2`** — Core NiFi properties. `provenanceStorage` is how much disk to dedicate to provenance events (NiFi's lineage tracking).
- **`# 3`** — Authentication via OIDC. NiFi natively supports OIDC, LDAP, mTLS, or simple username/password.
- **`# 4`** — Embedded Zookeeper. For multi-cluster deployments you might point to an external ZK.
- **`# 5`** — Four separate persistent volumes per node (NiFi keeps flowfiles, content, and provenance in separate stores).
- **`# 6`** — Ingress via the AWS ALB controller (see §14.4). HTTPS-only.
- **`# 7`** — Prometheus metrics endpoint (NiFi's built-in reporter).

For larger flows, manage flow definitions as code via [NiFi Registry](https://nifi.apache.org/registry/), backed by git. Terraform provisions the cluster; NiFi Registry handles flow versioning.

> **🔗 References:**
> - Apache NiFi docs — https://nifi.apache.org/docs.html
> - The Cetic NiFi Helm chart — https://github.com/cetic/helm-nifi
> - NiFi Registry — https://nifi.apache.org/registry/

## 17.3 OpenSearch

> **📚 Background:** [OpenSearch](https://opensearch.org/) is the open-source fork of Elasticsearch (after Elastic's 2021 license change). It's a distributed search and analytics engine — full-text search, structured queries, time-series logs, geospatial. Common uses: log search, observability, product search, security analytics.

### Option A: Amazon OpenSearch Service (managed) — annotated

```hcl
resource "aws_security_group" "opensearch" {
  name   = "${var.name}-os"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.client_security_group_ids
  }
}

resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "os_slow" {
  name              = "/aws/opensearch/${var.name}/slow"
  retention_in_days = 30
}

# 1
resource "aws_opensearch_domain" "main" {
  domain_name    = var.name
  engine_version = "OpenSearch_2.15"

  # 2
  cluster_config {
    instance_type            = "r6g.large.search"
    instance_count           = 3
    zone_awareness_enabled   = true
    zone_awareness_config { availability_zone_count = 3 }
    dedicated_master_enabled = true
    dedicated_master_type    = "r6g.large.search"
    dedicated_master_count   = 3
  }

  # 3
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 100
    throughput  = 250
    iops        = 3000
  }

  # 4
  vpc_options {
    subnet_ids         = slice(var.private_subnet_ids, 0, 3)
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest         { enabled = true }
  node_to_node_encryption { enabled = true }

  # 5
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  # 6
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = var.master_role_arn
    }
  }

  # 7
  log_publishing_options {
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.os_slow.arn
  }

  depends_on = [aws_iam_service_linked_role.opensearch]
}
```

**Line-by-line:**

- **`# 1`** — The domain (Amazon's name for a cluster).
- **`# 2`** — Cluster topology: 3 data nodes (the workhorses) + 3 dedicated master nodes (split-brain prevention). Both placed across 3 AZs.
- **`# 3`** — Storage: 100 GiB gp3 per node with provisioned throughput/IOPS.
- **`# 4`** — Deploy inside your VPC (private subnets), reachable only via the security group.
- **`# 5`** — Force HTTPS with a modern TLS policy.
- **`# 6`** — Fine-grained access control using IAM (no internal username DB).
- **`# 7`** — Ship slow query logs to CloudWatch.

> **🔗 References:**
> - OpenSearch Service docs — https://docs.aws.amazon.com/opensearch-service/
> - `aws_opensearch_domain` — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain

### Option B: Self-hosted via the OpenSearch Operator on Kubernetes

```hcl
resource "helm_release" "opensearch_operator" {
  name             = "opensearch-operator"
  namespace        = "opensearch-operator-system"
  repository       = "https://opster.github.io/opensearch-k8s-operator/"
  chart            = "opensearch-operator"
  version          = "2.6.1"
  create_namespace = true
}

resource "kubernetes_manifest" "os_cluster" {
  manifest = yamldecode(<<-YAML
    apiVersion: opensearch.opster.io/v1
    kind: OpenSearchCluster
    metadata:
      name: prod
      namespace: opensearch
    spec:
      general:
        version: "2.15.0"
        serviceName: opensearch
      dashboards:
        enable: true
        version: "2.15.0"
        replicas: 2
      nodePools:
        - component: masters
          replicas: 3
          diskSize: "20Gi"
          roles: ["cluster_manager"]
          resources:
            requests: { memory: 2Gi, cpu: "1" }
        - component: data
          replicas: 3
          diskSize: "200Gi"
          roles: ["data", "ingest"]
          resources:
            requests: { memory: 8Gi, cpu: "2" }
            limits:   { memory: 8Gi }
  YAML
  )
  depends_on = [helm_release.opensearch_operator]
}
```

Two node pools: dedicated masters and data nodes. The OpenSearch Operator handles upgrades, scaling, and security.

> **🔗 References:**
> - OpenSearch Kubernetes Operator — https://github.com/opensearch-project/opensearch-k8s-operator
> - OpenSearch documentation — https://opensearch.org/docs/

## 17.4 Cross-component dependencies in Terragrunt — putting it all together

The whole point of the layered Terragrunt setup is **wiring these systems together cleanly**:

```
live/prod/eu-west-1/
├── 10-network/                  # VPC
├── 30-eks/                      # cluster
├── 40-msk/                      # depends on network
├── 41-opensearch/               # depends on network + eks SGs
└── 50-apps/
    └── ingestion/               # depends on msk + opensearch + eks
```

`50-apps/ingestion/terragrunt.hcl`:

```hcl
include "root" { path = find_in_parent_folders() }

terraform {
  source = "git::https://github.com/mycompany/tf-modules.git//app-ingestion?ref=v1.2.0"
}

dependency "msk"        { config_path = "../../40-msk" }
dependency "opensearch" { config_path = "../../41-opensearch" }
dependency "eks"        { config_path = "../../30-eks" }

inputs = {
  kafka_brokers       = dependency.msk.outputs.bootstrap_brokers_sasl_iam
  opensearch_endpoint = dependency.opensearch.outputs.endpoint
  cluster_name        = dependency.eks.outputs.cluster_name
}
```

Now `terragrunt apply` on the `ingestion` folder automatically ensures msk, opensearch, and eks are up to date first — and reads their outputs to wire them in. This is the layered architecture paying off.

---

# 18. Observability

## 18.1 The CNCF observability stack

> **📚 Background:** "Observability" means being able to ask questions about your running system's behavior without redeploying. The three pillars (Logs, Metrics, Traces) plus newer additions (Profiles, Events) are the data types. The mainstream open-source tooling, all CNCF projects:
>
> - **[Prometheus](https://prometheus.io/)** — pull-based metrics storage with PromQL query language.
> - **[Grafana](https://grafana.com/)** — dashboards and alerting UI; queries Prometheus, Loki, Tempo, and dozens of others.
> - **[OpenTelemetry (OTel)](https://opentelemetry.io/)** — vendor-neutral instrumentation API and SDK. Becoming the universal standard for traces, increasingly for metrics and logs too.
> - **[Loki](https://grafana.com/oss/loki/)** — Grafana Labs' log aggregation system. Cheap, indexed by label only.
> - **[Tempo](https://grafana.com/oss/tempo/)** — Grafana Labs' distributed tracing backend.
>
> The de facto Kubernetes deployment is the **[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)** Helm chart — Prometheus Operator + Grafana + Alertmanager + node-exporter + kube-state-metrics, all wired up.

> **🔗 References:**
> - The Prometheus book (free, online) — https://prometheus.io/docs/introduction/overview/
> - OpenTelemetry docs — https://opentelemetry.io/docs/
> - Grafana Labs LGTM stack — https://grafana.com/oss/
> - Google's *Observability Engineering* book — https://www.oreilly.com/library/view/observability-engineering/9781492076438/

## 18.2 Deploying kube-prometheus-stack — annotated

```hcl
resource "random_password" "grafana" {
  length  = 24
  special = false
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kps"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "62.6.0"
  create_namespace = true

  values = [yamlencode({
    # 1
    prometheus = {
      prometheusSpec = {
        retention      = "30d"
        retentionSize  = "180GiB"

        # 2
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              accessModes      = ["ReadWriteOnce"]
              resources = { requests = { storage = "200Gi" } }
            }
          }
        }

        # 3
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues           = false

        scrapeInterval = "30s"

        resources = {
          requests = { cpu = "1", memory = "4Gi" }
          limits   = { cpu = "2", memory = "8Gi" }
        }
      }
    }

    # 4
    grafana = {
      adminPassword = random_password.grafana.result
      persistence = {
        enabled          = true
        size             = "10Gi"
        storageClassName = "gp3"
      }

      ingress = {
        enabled          = true
        ingressClassName = "alb"
        hosts            = ["grafana.prod.example.com"]
        annotations = {
          "alb.ingress.kubernetes.io/scheme"       = "internal"
          "alb.ingress.kubernetes.io/target-type"  = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\": 443}]"
        }
      }

      # 5
      additionalDataSources = [
        { name = "Loki",  type = "loki",  url = "http://loki:3100"  },
        { name = "Tempo", type = "tempo", url = "http://tempo:3100" },
      ]
    }

    # 6
    alertmanager = {
      config = {
        route = {
          receiver = "slack"
          group_by = ["alertname", "cluster", "service"]
        }
        receivers = [{
          name = "slack"
          slack_configs = [{
            api_url = var.slack_webhook_url
            channel = "#alerts-prod"
            title   = "{{ .GroupLabels.alertname }}"
          }]
        }]
      }
    }
  })]
}
```

**Line-by-line:**

- **`# 1`** — Prometheus settings. 30-day retention, capped at 180GiB.
- **`# 2`** — Persistent storage so metrics survive pod restarts. 200Gi gp3.
- **`# 3`** — **The key magic settings.** With these set to `false`, Prometheus auto-discovers any `ServiceMonitor`, `PodMonitor`, or `PrometheusRule` resource in the cluster — even if another team installed it via a separate Helm chart. With `true`, only resources with matching Helm labels are picked up.
- **`# 4`** — Grafana. Admin password generated; persistent storage; exposed via ALB.
- **`# 5`** — Pre-configure Loki and Tempo as Grafana data sources (we install them in §18.4).
- **`# 6`** — Alertmanager configuration: route everything to Slack.

> **🔗 References:**
> - kube-prometheus-stack chart — https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
> - ServiceMonitor and PodMonitor CRDs — https://prometheus-operator.dev/docs/operator/design/
> - PromQL tutorial — https://prometheus.io/docs/prometheus/latest/querying/basics/

## 18.3 Scraping non-Kubernetes targets

You'll often need to scrape things that live outside the cluster — MSK brokers, RDS Performance Insights, application servers on EC2.

```hcl
resource "kubernetes_manifest" "scrape_msk" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "ScrapeConfig"
    metadata = {
      name      = "msk"
      namespace = "monitoring"
      labels    = { release = "kps" }
    }
    spec = {
      staticConfigs = [{
        targets = [
          "b-1.msk-cluster.kafka.eu-west-1.amazonaws.com:11001",
          "b-2.msk-cluster.kafka.eu-west-1.amazonaws.com:11001",
          "b-3.msk-cluster.kafka.eu-west-1.amazonaws.com:11001",
        ]
        labels = { service = "msk" }
      }]
      metricsPath = "/metrics"
    }
  }
}
```

`ScrapeConfig` is a Prometheus Operator CRD (0.65+) that defines arbitrary scrape jobs without modifying the main Prometheus config.

## 18.4 OpenTelemetry Collector — annotated

The OTel Collector is the recommended ingest path for traces, and increasingly metrics and logs. It sits between your apps and your backend (Tempo, Prometheus, Loki, or any vendor).

```hcl
resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  namespace        = "observability"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = "0.105.0"
  create_namespace = true

  values = [yamlencode({
    # 1
    mode         = "deployment"
    replicaCount = 2
    image        = { repository = "otel/opentelemetry-collector-contrib" }

    config = {
      # 2
      receivers = {
        otlp = {
          protocols = {
            grpc = { endpoint = "0.0.0.0:4317" }
            http = { endpoint = "0.0.0.0:4318" }
          }
        }
      }

      # 3
      processors = {
        batch          = { timeout = "10s" }
        memory_limiter = {
          check_interval         = "5s"
          limit_percentage       = 80
          spike_limit_percentage = 25
        }
        resourcedetection = { detectors = ["env", "ec2", "eks"] }
      }

      # 4
      exporters = {
        "otlp/tempo" = {
          endpoint = "tempo:4317"
          tls      = { insecure = true }
        }
        prometheusremotewrite = {
          endpoint = "http://kps-kube-prometheus-stack-prometheus:9090/api/v1/write"
        }
        debug = { verbosity = "basic" }
      }

      # 5
      service = {
        pipelines = {
          traces = {
            receivers  = ["otlp"]
            processors = ["memory_limiter", "batch", "resourcedetection"]
            exporters  = ["otlp/tempo"]
          }
          metrics = {
            receivers  = ["otlp"]
            processors = ["memory_limiter", "batch", "resourcedetection"]
            exporters  = ["prometheusremotewrite"]
          }
        }
      }
    }
  })]
}
```

**Line-by-line:**

- **`# 1`** — Run as a Deployment with 2 replicas. (For high-volume, consider DaemonSet for agent mode + Deployment for gateway mode.) The `-contrib` image includes many more receivers/exporters than the core image.
- **`# 2`** — Receivers: where data comes from. OTLP (the OpenTelemetry Protocol) accepts gRPC on 4317 and HTTP on 4318 — the standard ports.
- **`# 3`** — Processors: how data is transformed in-flight.
  - `batch` — group spans/metrics before exporting (efficient).
  - `memory_limiter` — refuses new data when memory is high to avoid OOMs.
  - `resourcedetection` — auto-add labels like region, AZ, instance ID, cluster name.
- **`# 4`** — Exporters: where data goes out.
  - `otlp/tempo` — forward traces to Tempo (same OTLP protocol).
  - `prometheusremotewrite` — push metrics into Prometheus's remote-write endpoint.
  - `debug` — log a sample to stdout (useful while bringing up the pipeline).
- **`# 5`** — Wire receivers → processors → exporters into named pipelines.

Applications then point at the collector:

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.observability:4317
export OTEL_SERVICE_NAME=my-app
export OTEL_RESOURCE_ATTRIBUTES=deployment.environment=prod
```

Then start emitting traces from any [OTel-instrumented SDK](https://opentelemetry.io/docs/languages/).

> **🔗 References:**
> - OpenTelemetry Collector docs — https://opentelemetry.io/docs/collector/
> - Collector configuration guide — https://opentelemetry.io/docs/collector/configuration/
> - OTel Helm charts — https://github.com/open-telemetry/opentelemetry-helm-charts

## 18.5 Tempo (traces) and Loki (logs)

```hcl
# 1
resource "helm_release" "tempo" {
  name       = "tempo"
  namespace  = "observability"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo-distributed"
  version    = "1.18.0"

  values = [yamlencode({
    storage = {
      trace = {
        backend = "s3"
        s3 = {
          bucket   = var.tempo_bucket
          endpoint = "s3.${var.region}.amazonaws.com"
          region   = var.region
        }
      }
    }
    ingester    = { replicas = 3 }
    distributor = { replicas = 3 }
    querier     = { replicas = 2 }
    compactor   = { replicas = 1 }
  })]
}

# 2
resource "helm_release" "loki" {
  name       = "loki"
  namespace  = "observability"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.11.0"

  values = [yamlencode({
    loki = {
      auth_enabled = false
      schemaConfig = {
        configs = [{
          from         = "2024-01-01"
          store        = "tsdb"
          object_store = "s3"
          schema       = "v13"
          index        = { prefix = "loki_index_", period = "24h" }
        }]
      }
      storage = {
        type        = "s3"
        bucketNames = {
          chunks = var.loki_bucket
          ruler  = var.loki_bucket
          admin  = var.loki_bucket
        }
        s3 = { region = var.region }
      }
    }
    write   = { replicas = 3 }
    read    = { replicas = 3 }
    backend = { replicas = 3 }
  })]
}
```

**Notes:**

- **`# 1`** — Tempo uses S3 for trace storage — extremely cheap. The "distributed" chart deploys separate ingester/distributor/querier/compactor components.
- **`# 2`** — Loki similarly uses S3. Three replicas each of write, read, and backend services for HA.

> **🔗 References:**
> - Tempo docs — https://grafana.com/docs/tempo/latest/
> - Loki docs — https://grafana.com/docs/loki/latest/

## 18.6 Dashboards as code

Grafana dashboards belong in git. The simplest pattern: put dashboard JSON files in a ConfigMap labeled `grafana_dashboard=1`. The Grafana sidecar auto-imports them.

```hcl
resource "kubernetes_config_map" "dashboards" {
  metadata {
    name      = "custom-dashboards"
    namespace = "monitoring"
    labels    = { grafana_dashboard = "1" }
  }
  data = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    f => file("${path.module}/dashboards/${f}")
  }
}
```

Drop any number of `.json` files in `./dashboards/`; they all appear in Grafana on next reconcile.

For more advanced workflows, see the [grafana/grafana](https://registry.terraform.io/providers/grafana/grafana/latest) Terraform provider, which manages dashboards, folders, data sources, and alerts via the Grafana API.

---

# 19. Load Balancing and Fault Tolerance

## 19.1 The big picture — three layers of load distribution

```
   Internet
       │
       ▼
   ┌───────────────────┐
   │ Anycast / Global  │   Route 53 / Azure DNS / Cloud DNS
   │   DNS layer       │   Latency-, geo-, or weighted-routed
   └─────────┬─────────┘
             │
             ▼  per-region
   ┌───────────────────┐
   │  Regional LB      │   ALB / NLB / App Gateway / Front Door
   │  (L4 or L7)       │   Health-checked targets
   └─────────┬─────────┘
             │
             ▼  inside cluster / service mesh
   ┌───────────────────┐
   │  Service-level    │   Kubernetes Service, Envoy, HAProxy
   │  load balancing   │   Istio, Linkerd, Consul
   └───────────────────┘
```

Terraform configures all three. Choose layers based on what you're protecting against:

| Failure mode                   | Mitigated by                                       |
| ------------------------------ | -------------------------------------------------- |
| Single instance crash          | Multiple targets behind a regional LB              |
| AZ outage                      | Multi-AZ targets; ALB is itself multi-AZ           |
| Region outage                  | Multi-region active/passive with DNS failover      |
| Bad deploy                     | Canary / blue-green deploys; circuit breakers      |
| Bot / DDoS                     | WAF, rate limiting, CloudFront, Front Door         |
| Slow dependency                | App-level timeouts + circuit breakers              |

## 19.2 AWS Application Load Balancer (L7)

```hcl
# 1
resource "aws_security_group" "alb" {
  name   = "${var.name}-alb"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

# 2
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = var.environment == "prod"
  drop_invalid_header_fields = true
  enable_http2               = true
  idle_timeout               = 60

  access_logs {
    bucket  = var.access_log_bucket
    prefix  = "${var.name}-alb"
    enabled = true
  }
}

# 3
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/healthz"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # 4
  deregistration_delay = 30
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

# 5
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 6
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 7 — Path-based routing
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern { values = ["/api/*"] }
  }
}
```

**Line-by-line:**

- **`# 1`** — Security group for the ALB itself: allow public HTTP/HTTPS.
- **`# 2`** — The ALB. `internal = false` makes it internet-facing. Deletion protection on prod. Access logs to S3 — invaluable for incident forensics.
- **`# 3`** — Target group. `target_type = "ip"` (for Fargate/EKS) vs `instance` (for EC2). Health checks every 15s with 2/3 thresholds (10x faster failover than the defaults).
- **`# 4`** — `deregistration_delay` is the connection draining window. 30s is usually enough; bump to 300s if you have long-lived connections.
- **`# 5`** — HTTPS listener with a modern TLS policy. ACM certificate provided.
- **`# 6`** — Permanent redirect HTTP → HTTPS.
- **`# 7`** — Path-based routing: `/api/*` goes to a different target group.

> **🔗 References:**
> - `aws_lb` resource — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
> - ALB documentation — https://docs.aws.amazon.com/elasticloadbalancing/latest/application/
> - TLS policies — https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html

## 19.3 Network Load Balancer (L4) — for non-HTTP

```hcl
resource "aws_lb" "nlb" {
  name               = "${var.name}-nlb"
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
  internal           = true

  enable_cross_zone_load_balancing = true
}
```

Use NLB for:
- Kafka clients (TCP, not HTTP)
- Database access points
- Mixed protocols
- Static IP requirements (NLB supports Elastic IPs)
- Extremely low latency / high throughput requirements

`enable_cross_zone_load_balancing = true` distributes traffic evenly across all backends regardless of AZ. **Costs slightly more in cross-AZ data transfer but gives much better balance** — recommended for most workloads.

> **🔗 Reference:** NLB docs — https://docs.aws.amazon.com/elasticloadbalancing/latest/network/

## 19.4 HAProxy ingress for fine-grained L7

```hcl
resource "helm_release" "haproxy_ingress" {
  name             = "haproxy-ingress"
  namespace        = "ingress-haproxy"
  repository       = "https://haproxy-ingress.github.io/charts"
  chart            = "haproxy-ingress"
  version          = "0.14.7"
  create_namespace = true

  values = [yamlencode({
    controller = {
      replicaCount = 3
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        }
      }
      stats   = { enabled = true }
      metrics = { enabled = true }
    }
  })]
}
```

Use HAProxy when ALB's feature set isn't enough — custom Lua rules, fine-grained rate limiting, complex routing tables, ACL-based authorization. The HAProxy Ingress sits behind an NLB so you keep AWS's L4 perks while getting HAProxy's L7 power.

> **🔗 Reference:** HAProxy Ingress — https://haproxy-ingress.github.io/

## 19.5 Auto Scaling Groups — annotated

```hcl
# 1
resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  user_data     = base64encode(file("${path.module}/user-data.sh"))

  iam_instance_profile { name = aws_iam_instance_profile.ec2.name }
  vpc_security_group_ids = [aws_security_group.web.id]

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = var.name }
  }

  lifecycle { create_before_destroy = true }
}

# 2
resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.name}-"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 3
  max_size            = 30
  desired_capacity    = 3

  health_check_type         = "ELB"
  health_check_grace_period = 60

  target_group_arns = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # 3
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 60
    }
  }

  lifecycle { create_before_destroy = true }
}

# 4
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
```

**Line-by-line:**

- **`# 1`** — Launch template defines *how* to launch new instances. `create_before_destroy` is critical — without it, replacing the template would destroy then recreate, causing downtime.
- **`# 2`** — The Auto Scaling Group itself. `health_check_type = "ELB"` uses the load balancer's health checks (not just EC2 status checks) — much faster recovery from app-level failures.
- **`# 3`** — Instance refresh policy: when the launch template changes (new AMI), roll instances one at a time, maintaining 90% healthy. This is **zero-downtime AMI updates**.
- **`# 4`** — CPU-based autoscaling. The ASG adjusts desired_capacity automatically.

> **🔗 References:**
> - `aws_autoscaling_group` — https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
> - Instance refresh — https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html

## 19.6 Route 53 health checks + DNS failover

```hcl
# 1
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.main.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/healthz"
  failure_threshold = 3
  request_interval  = 30
}

# 2
resource "aws_route53_record" "primary" {
  zone_id = var.zone_id
  name    = "api.example.com"
  type    = "A"

  set_identifier  = "primary"
  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# 3
resource "aws_route53_record" "secondary" {
  zone_id = var.zone_id
  name    = "api.example.com"
  type    = "A"

  set_identifier = "secondary"
  failover_routing_policy { type = "SECONDARY" }

  alias {
    name                   = var.dr_region_lb_dns
    zone_id                = var.dr_region_lb_zone_id
    evaluate_target_health = true
  }
}
```

**Line-by-line:**

- **`# 1`** — Health check from Route 53's distributed checkers. With 30s interval × 3 failures = ~90s to detect.
- **`# 2`** — Primary DNS record pointing at the regional ALB. `failover_routing_policy = PRIMARY` plus a health check means: serve this record while healthy.
- **`# 3`** — Secondary record pointing at a DR region's LB. Served only when the primary health check fails.

For active-active across regions, use `latency_routing_policy` or `geolocation_routing_policy` instead.

> **🔗 Reference:** Route 53 routing policies — https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html

## 19.7 Azure equivalents

| AWS              | Azure                                                                       |
| ---------------- | --------------------------------------------------------------------------- |
| ALB              | Application Gateway (L7, WAF built in)                                      |
| NLB              | Azure Load Balancer Standard (L4)                                           |
| CloudFront + R53 | Front Door (global L7 + WAF + CDN)                                          |
| Route 53         | Azure DNS / Traffic Manager (DNS routing)                                   |

`azurerm_application_gateway` is verbose; the [Azure/application-gateway/azurerm](https://registry.terraform.io/modules/Azure/application-gateway/azurerm/latest) community module is recommended.

## 19.8 Fault tolerance checklist

- [ ] **Multiple AZs at every layer.** 2+ for dev, 3 for prod.
- [ ] **No single replica** of any stateful service. 3+ for quorum systems (etcd, Kafka, ZK).
- [ ] **Health checks at every layer.** LB → instance, instance → app, app → dependencies.
- [ ] **Timeouts and retries everywhere.** Network is unreliable.
- [ ] **Circuit breakers.** App-level libraries (resilience4j, Hystrix) or service mesh (Istio).
- [ ] **Graceful degradation.** Serve stale cache, fail open vs closed appropriately.
- [ ] **Backups tested.** Quarterly restore drills, not just nightly snapshots.
- [ ] **Chaos testing.** [AWS Fault Injection Service](https://aws.amazon.com/fis/) / [Azure Chaos Studio](https://azure.microsoft.com/en-us/products/chaos-studio).
- [ ] **Documented runbooks.** Linked from alerts.
- [ ] **Disaster recovery plan.** Tested annually.

Terraform makes multi-AZ infrastructure trivial. **Application resilience is the harder, human-driven work.**

---

# 20. CI/CD and Team Workflows

## 20.1 The PR-driven workflow

The standard pattern:

```
1. Engineer opens PR with infra changes
        │
        ▼
2. CI runs: fmt check, validate, plan
        │
        ▼
3. Plan is posted as a PR comment
        │
        ▼
4. Reviewer approves; CI re-runs plan to confirm no drift
        │
        ▼
5. PR merged to main
        │
        ▼
6. CI runs apply (with manual approval for prod)
```

Key properties:

- Every change goes through review.
- Plans are visible in the PR — no "trust me, it'll work."
- Apply happens in CI with consistent tooling — no laptop drift.
- Prod requires explicit human approval.

## 20.2 GitHub Actions — full example annotated

`.github/workflows/terragrunt.yml`:

```yaml
name: Terragrunt

# 1
on:
  pull_request:
    paths: ['live/**', 'modules/**']
  push:
    branches: [main]
    paths: ['live/**', 'modules/**']

# 2
permissions:
  id-token: write       # for AWS OIDC
  contents: read
  pull-requests: write  # to comment plans

jobs:
  # 3
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      dirs: ${{ steps.diff.outputs.dirs }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - id: diff
        run: |
          BASE=${{ github.event.pull_request.base.sha || 'HEAD~1' }}
          dirs=$(git diff --name-only "$BASE"..HEAD live/ \
            | xargs -n1 dirname | sort -u \
            | grep -E '^live/.+/.+' | jq -R . | jq -s -c .)
          echo "dirs=$dirs" >> "$GITHUB_OUTPUT"

  # 4
  plan:
    needs: detect-changes
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        dir: ${{ fromJson(needs.detect-changes.outputs.dirs) }}
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.5
          terraform_wrapper: false

      - uses: gruntwork-io/terragrunt-action@v2
        with:
          tg_version: 0.67.0

      # 5
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111122223333:role/GHActionsTerraform
          aws-region: eu-west-1

      - name: Terragrunt plan
        working-directory: ${{ matrix.dir }}
        run: |
          terragrunt init -input=false
          terragrunt plan -no-color -input=false -out=plan.tfplan 2>&1 | tee plan.txt

      # 6
      - name: Comment plan on PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = '### Plan for `${{ matrix.dir }}`\n```\n' +
              fs.readFileSync('${{ matrix.dir }}/plan.txt','utf8').slice(0, 60000) +
              '\n```';
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body
            });

  # 7
  apply:
    needs: detect-changes
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    strategy:
      max-parallel: 1
      matrix:
        dir: ${{ fromJson(needs.detect-changes.outputs.dirs) }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: 1.9.5, terraform_wrapper: false }
      - uses: gruntwork-io/terragrunt-action@v2
        with: { tg_version: 0.67.0 }
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111122223333:role/GHActionsTerraform
          aws-region: eu-west-1
      - name: Terragrunt apply
        working-directory: ${{ matrix.dir }}
        run: |
          terragrunt init -input=false
          terragrunt apply -input=false -auto-approve
```

**Line-by-line:**

- **`# 1`** — Trigger: on PRs and on pushes to main, but only when infra paths change.
- **`# 2`** — Permissions: `id-token: write` is essential for **OIDC federation** — GitHub mints a short-lived token that AWS IAM trusts. No static AWS credentials in GitHub.
- **`# 3`** — Detect which directories changed in the PR. Output as a JSON array for matrix usage.
- **`# 4`** — `plan` job: matrix-parallel across changed directories.
- **`# 5`** — Assume an IAM role via OIDC. Set up on the AWS side with an OIDC provider trusting `token.actions.githubusercontent.com`.
- **`# 6`** — Post the plan as a PR comment. Reviewers see exactly what will change.
- **`# 7`** — Apply job: only on push to main, restricted to one directory at a time. `environment: production` triggers GitHub's environment protection rules (required approvers, wait timers).

> **🔗 References:**
> - GitHub Actions OIDC with AWS — https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
> - Terragrunt GitHub Action — https://github.com/gruntwork-io/terragrunt-action
> - GitHub environments — https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment

## 20.3 GitLab CI alternative

```yaml
stages: [validate, plan, apply]

variables:
  TF_VERSION: "1.9.5"
  TG_VERSION: "0.67.0"

.terragrunt: &terragrunt
  image: alpine/terragrunt:${TG_VERSION}
  before_script:
    - aws sts get-caller-identity
  rules:
    - changes: [live/**/*, modules/**/*]

plan:
  <<: *terragrunt
  stage: plan
  script:
    - cd ${TG_DIR}
    - terragrunt init -input=false
    - terragrunt plan -input=false -out=plan.tfplan
  artifacts:
    paths: ["${TG_DIR}/plan.tfplan"]
    expire_in: 1 week

apply:
  <<: *terragrunt
  stage: apply
  when: manual
  only: [main]
  script:
    - cd ${TG_DIR}
    - terragrunt apply -input=false plan.tfplan
```

For OIDC with GitLab and AWS, see [GitLab's docs on configuring OpenID Connect](https://docs.gitlab.com/ee/ci/cloud_services/aws/).

## 20.4 Policy as Code

Don't rely on "the reviewer will catch it." Enforce policies automatically.

### Checkov / tfsec / Trivy — static analysis

```bash
# Checkov on the whole tree
checkov -d . --framework terraform
```

Catches: missing encryption, public buckets, overly-permissive SGs, missing logging, hardcoded secrets, and dozens of cloud-specific issues. In CI:

```yaml
- name: Checkov
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: live/
    framework: terraform_plan
    file: plan.json
```

### OPA / Conftest — custom policies

[Open Policy Agent](https://www.openpolicyagent.org/) lets you write custom rules in Rego:

```rego
# policies/no-public-ingress.rego
package terraform.aws

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group_rule"
  resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
  resource.change.after.from_port != 443
  msg := sprintf("SG rule %s allows 0.0.0.0/0 on non-443 port", [resource.address])
}
```

Run:

```bash
terraform show -json plan.tfplan > plan.json
conftest test plan.json -p policies/
```

### Sentinel (Terraform Cloud / Enterprise)

HashiCorp's native policy language; tightly integrated with Terraform Cloud's run workflow.

> **🔗 References:**
> - Checkov — https://www.checkov.io/
> - tfsec — https://aquasecurity.github.io/tfsec/
> - OPA — https://www.openpolicyagent.org/docs/
> - Conftest — https://www.conftest.dev/
> - Sentinel — https://developer.hashicorp.com/sentinel/intro

## 20.5 Secrets — how to handle them safely

**Never commit secrets to git.** Options, in roughly decreasing order of preference:

| Approach                                | Notes                                                    |
| --------------------------------------- | -------------------------------------------------------- |
| **HashiCorp Vault (dynamic creds)**     | Short-lived DB creds, AWS keys generated per request     |
| **AWS Secrets Manager / SSM**           | Read via data source; encrypt with KMS                   |
| **Azure Key Vault**                     | Same idea on Azure                                       |
| **External Secrets Operator** (for K8s) | Sync from any vault to K8s Secrets at runtime            |
| **SOPS** + age/KMS                      | Commit encrypted YAML; decrypt at apply time             |
| **Environment variables** (CI)          | Acceptable for service-account credentials               |

Example — reading from Secrets Manager:

```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "myapp/db-password"
}

resource "aws_rds_cluster" "main" {
  master_password = data.aws_secretsmanager_secret_version.db.secret_string
}
```

> **⚠️ Caveat:** values read via data sources end up in state. Encrypt state at rest, restrict who can read it, and consider using `external` data source + ephemeral retrieval if your threat model demands it.

> **🔗 References:**
> - HashiCorp Vault — https://www.vaultproject.io/
> - SOPS — https://github.com/getsops/sops
> - External Secrets Operator — https://external-secrets.io/

## 20.6 Hosted alternatives — when to outgrow homegrown CI

| Service                  | Notes                                                              |
| ------------------------ | ------------------------------------------------------------------ |
| **[Terraform Cloud / HCP Terraform](https://www.hashicorp.com/cloud-platform/terraform)** | HashiCorp's SaaS; Sentinel built-in    |
| **[Spacelift](https://spacelift.io/)**     | Stack-oriented; good for non-Terraform IaC too                    |
| **[env0](https://www.env0.com/)**          | Self-service IaC for app teams                                    |
| **[Atlantis](https://www.runatlantis.io/)** | Free, self-hosted; the original PR-comment driven runner          |
| **[Scalr](https://scalr.com/)**            | Multi-tier RBAC, enterprise focus                                 |

These give you: a web UI showing plan diffs, drift detection on a schedule, policy enforcement, RBAC/SSO, cost estimation via [Infracost](https://www.infracost.io/).

---

# 21. Troubleshooting & Best Practices

## 21.1 Common errors and fixes

### `Error: Backend configuration changed`

You changed the backend block (different bucket/key/region). Terraform refuses to silently re-key state.

```bash
terraform init -reconfigure       # discard old backend, use new
terraform init -migrate-state     # copy state from old backend to new
```

### `Error acquiring the state lock`

A previous run died holding the lock, or someone else is applying right now. First confirm nobody else is running, then:

```bash
terraform force-unlock <LOCK_ID>
# Terragrunt:
terragrunt force-unlock <LOCK_ID>
```

The lock ID is shown in the error message.

### `Error: Inconsistent dependency lock file`

A provider was upgraded but `.terraform.lock.hcl` is stale (e.g., teammate bumped a version without re-running `init`).

```bash
terraform init -upgrade
git add .terraform.lock.hcl
git commit -m "chore: update provider lock"
```

### Drift — "Plan shows changes I didn't make"

Something modified the resource outside Terraform (someone clicked in the console; an auto-tagging Lambda added tags; ASG scaled). You have three options:

1. **Restore reality to match code** — usually the right answer. Click-fix the offending change so it matches Terraform's declaration.
2. **Update code to match reality** — if the change should stick.
3. **Add to `ignore_changes`** — if it's a value Terraform shouldn't manage (e.g., a tag written by AWS itself, or `desired_count` managed by autoscaling).

Set up **scheduled drift detection** in CI (run `terraform plan -detailed-exitcode` nightly; alert if exit code 2).

### `Error: cycle: module.a, module.b`

A circular dependency. Refactor: extract the shared dependency into a third module that both depend on.

### Stuck "destroying" forever

Usually an actual cloud-side issue: a load balancer with active targets, a network interface in use, an EKS cluster with pods still running. Look in the cloud console for the underlying error. Use `terraform state rm` only as a last resort and only after manually deleting the resource on the cloud side.

### "Provider produced inconsistent final plan"

A provider returned a different value at apply time than it predicted at plan time. Usually a provider bug or an interaction with `lifecycle { ignore_changes }`. Try:

```bash
terraform refresh
terraform plan
# If still broken: pin to a known-good provider version
```

### `Error: Provider configuration not present`

You removed a resource that was using a provider alias, but the alias config is still referenced somewhere else. Don't delete provider blocks until all resources using them are gone.

## 21.2 Debugging — enable trace logs

```bash
# Verbose Terraform logs
TF_LOG=DEBUG terraform apply 2> tf.log

# Or even more verbose
TF_LOG=TRACE terraform apply 2> tf.log

# Just the provider
TF_LOG_PROVIDER=DEBUG terraform apply 2> tf.log

# To a file instead of stderr
TF_LOG_PATH=tf.log TF_LOG=DEBUG terraform apply
```

For Terragrunt:

```bash
terragrunt --log-level debug apply
# Older syntax: terragrunt --terragrunt-log-level debug apply
```

For state mysteries:

```bash
terraform state list                   # all resources
terraform state show <addr>            # one resource
terraform graph | dot -Tsvg > graph.svg  # dependency DAG (needs graphviz)
```

> **🔗 References:**
> - Debugging Terraform — https://developer.hashicorp.com/terraform/internals/debugging
> - Terraform CLI commands — https://developer.hashicorp.com/terraform/cli/commands

## 21.3 Performance tips

| Tip                                        | When to use                                          |
| ------------------------------------------ | ---------------------------------------------------- |
| `-parallelism=N`                           | Default is 10. Bump for fast networks; lower if rate-limited. |
| `-refresh=false` on plan                   | Skip refresh for fast iteration. **Re-enable for prod.** |
| `-target` to apply one resource            | Emergency only — partial state hides issues          |
| Saved plan file                            | `plan -out=plan.tfplan` → `apply plan.tfplan` removes race conditions |
| Split state earlier                        | A 1000-resource state has slow refresh / risky apply |
| Use `for_each` over `count`                | Adding items doesn't shift indexes                   |

## 21.4 Security best practices

1. **Encrypt state at rest** (S3 SSE-S3 minimum, SSE-KMS for sensitive workloads).
2. **Restrict state access** — read access to state ≈ read access to secrets.
3. **Use OIDC for CI** — no long-lived cloud keys in GitHub/GitLab.
4. **Pin provider and module versions** — supply chain attacks are real.
5. **Run static analysis in CI** — Checkov, tfsec, on every PR.
6. **IAM least privilege** — Terraform runners shouldn't be `*:*` admins.
7. **Never hard-code secrets.** Use Secrets Manager / Key Vault / Vault.
8. **Tag everything** — `ManagedBy=terraform` signals "don't click-fix this."
9. **Defense in depth** — AWS Config / Azure Policy alongside Terraform.
10. **Review destroy plans** — `terraform plan -destroy` before any `destroy`.
11. **Multi-account boundaries** — prod creds shouldn't be available outside prod CI jobs.
12. **Code-sign your modules** if your supply chain is critical (Sigstore/cosign).

## 21.5 Code style

- **Always run `terraform fmt`.** Enforce in pre-commit and CI.
- **`_` vs `-`** — HCL identifiers (resource local names, variable names) can't contain hyphens. Use hyphens only in the *string* attributes (names visible in the cloud).
- **Split files when they grow.** A `main.tf` above ~300 lines is hard to navigate. Group by domain: `iam.tf`, `network.tf`, `compute.tf`.
- **Don't `include` files just to reduce length.** Locality matters more than file size.
- **Comment intent, not mechanics.** "RDS Multi-AZ in prod only (~$200/mo extra)" beats "this enables multi-AZ."
- **Outputs first in `outputs.tf`, internals last in `main.tf`.** Readers should see the interface before the implementation.

## 21.6 Things you should NEVER do

- ❌ Commit `terraform.tfstate` to git.
- ❌ Use Terraform workspaces for environments.
- ❌ Apply from your laptop to prod. CI only.
- ❌ "Just this once" click-fix in the console.
- ❌ Use `null_resource` with `local-exec` to do real provisioning work.
- ❌ Leave `lifecycle { prevent_destroy = true }` off your production databases.
- ❌ Commit `*.tfvars` with secrets.
- ❌ `terraform destroy` without reading the plan in full.
- ❌ Pin to `latest`. Always pin versions.
- ❌ Skip `terraform plan` before apply. Ever.
- ❌ Run `apply` against a state file someone else owns without coordinating.
- ❌ Use `-target` as anything other than an emergency tool.

## 21.7 Team norms worth adopting

- **A bot posts plans on every PR.** Human review scopes to "is this what I expect?"
- **Required reviewers per directory.** GitHub `CODEOWNERS` file: platform team owns `live/prod/**`, app teams own their own apps.
- **Atomic PRs.** One concern per PR. Don't mix VPC + EKS + app changes.
- **Document `WHY` in commit messages.** Not "updated eks." Future you will thank present you.
- **Weekly drift detection.** Run `terragrunt run --all plan` on a schedule.
- **Tag releases of `modules/`.** Treat them like the libraries they are.
- **Onboarding day-one task.** Every new engineer should `terragrunt apply` in a sandbox environment on their first day.
- **Postmortem culture.** When apply breaks prod, write up what happened and improve guardrails.

---

# 22. Error Handling and Conditional Logic

> **📚 What this section covers:** Terraform has no `try`/`catch` like a real programming language, but it has its own set of mechanisms for handling errors and expressing conditional behavior: variable validation, `precondition`/`postcondition`/`check` blocks, the `try()` and `can()` functions, conditional resource creation via `count`/`for_each`, conditional nested blocks via `dynamic`, fallback expressions, and CI-level exit-code handling. This section walks through every one of them with annotated examples.

## 22.1 Conditional resources — the `count = 0 or 1` pattern

> **📚 Background:** Terraform has no `if resource { ... }` syntax. The idiomatic way to create a resource *only sometimes* is to use `count = condition ? 1 : 0`. When the condition is false, `count = 0` produces zero copies of the resource — i.e., it's not created. When true, one copy exists.

```hcl
# 1
variable "create_monitoring_bucket" {
  type    = bool
  default = true
}

# 2
resource "aws_s3_bucket" "monitoring" {
  count  = var.create_monitoring_bucket ? 1 : 0
  bucket = "${var.name}-monitoring-${random_id.suffix.hex}"
}

# 3
resource "aws_s3_bucket_versioning" "monitoring" {
  count  = var.create_monitoring_bucket ? 1 : 0
  bucket = aws_s3_bucket.monitoring[0].id
  versioning_configuration { status = "Enabled" }
}

# 4
output "monitoring_bucket_arn" {
  value = var.create_monitoring_bucket ? aws_s3_bucket.monitoring[0].arn : null
}
```

**Line-by-line:**

- **`# 1`** — A boolean feature flag.
- **`# 2`** — The bucket is created only when the flag is true.
- **`# 3`** — Any *dependent* resource also needs the same conditional, otherwise it tries to reference `aws_s3_bucket.monitoring[0]` when the list is empty. Indexing into an empty list = plan-time error.
- **`# 4`** — Outputs need the same guard. `try(aws_s3_bucket.monitoring[0].arn, null)` is an alternative (see §22.6 on `try()`).

> **⚠️ Gotcha — accessing conditional resources:** When you use `count = ? 1 : 0`, the resource is always *referenced* as `aws_s3_bucket.monitoring[0]` — even though you intuitively think of it as a single resource. Forgetting the `[0]` is a common error. Some teams prefer the `one()` function (§22.7) for safer access.

> **🔗 Reference:** Resources with count — https://developer.hashicorp.com/terraform/language/meta-arguments/count

## 22.2 Conditional resources — the `for_each` filtering pattern

For collections of conditionally-created items, `for_each` with a filter is cleaner than `count`:

```hcl
# 1
variable "users" {
  type = map(object({
    email     = string
    is_admin  = bool
    create_kp = bool
  }))
  default = {
    alice = { email = "alice@co", is_admin = true,  create_kp = true  }
    bob   = { email = "bob@co",   is_admin = false, create_kp = true  }
    carol = { email = "carol@co", is_admin = false, create_kp = false }
  }
}

# 2
resource "aws_iam_user" "team" {
  for_each = var.users
  name     = each.key
}

# 3
resource "aws_iam_user_policy_attachment" "admin" {
  for_each   = { for k, v in var.users : k => v if v.is_admin }
  user       = aws_iam_user.team[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 4
resource "aws_iam_access_key" "kp" {
  for_each = { for k, v in var.users : k => v if v.create_kp }
  user     = aws_iam_user.team[each.key].name
}
```

**Line-by-line:**

- **`# 1`** — A map of user definitions. Each user has flags controlling what's created for them.
- **`# 2`** — Always create the user.
- **`# 3`** — Attach the admin policy *only* if the user is admin. The `for k, v in var.users : k => v if v.is_admin` produces a filtered map. Carol and Bob get skipped here.
- **`# 4`** — Same pattern for access key creation.

Compared to `count`, this pattern:
- Doesn't shift indexes when items are added or removed.
- Doesn't require `[0]`-style indexing.
- Reads more like English: "for each user where condition X".

## 22.3 Conditional nested blocks — `dynamic` blocks

> **📚 Background:** Some resources have nested blocks that you want to include conditionally — e.g., add a `logging` block only when a log destination is provided. Plain Terraform can't say "if X then include this block." The `dynamic` block solves this by treating block presence as a `for_each` iteration.

```hcl
# 1
variable "ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    sg_ids      = optional(list(string))
  }))
  default = []
}

# 2
resource "aws_security_group" "this" {
  name   = var.name
  vpc_id = var.vpc_id

  # 3
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.sg_ids
    }
  }

  # 4
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Line-by-line:**

- **`# 1`** — A flexible variable accepting any number of ingress rules.
- **`# 2`** — The security group itself.
- **`# 3`** — `dynamic "ingress"` generates one `ingress { ... }` block per item in the list. Inside the `content { ... }`, `ingress.value.<field>` accesses the current iteration's data. If `var.ingress_rules = []`, no ingress blocks are generated.
- **`# 4`** — Regular (non-dynamic) `egress` block, always present.

### Conditional dynamic — generate a block only when condition is met

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.name

  # 1
  dynamic "logging" {
    for_each = var.log_bucket != null ? [1] : []
    content {
      target_bucket = var.log_bucket
      target_prefix = "logs/"
    }
  }

  # 2
  dynamic "replication_configuration" {
    for_each = var.enable_replication ? [1] : []
    content {
      role = aws_iam_role.replication[0].arn
      rules {
        id     = "replicate-everything"
        status = "Enabled"
        destination {
          bucket        = var.replication_dest_arn
          storage_class = "STANDARD_IA"
        }
      }
    }
  }
}
```

The pattern `for_each = condition ? [1] : []` is idiomatic Terraform: iterate over a one-element list when the condition is true; iterate over an empty list when false (producing zero blocks).

> **🔗 Reference:** Dynamic blocks — https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks

## 22.4 Conditional module calls

You can use the same `count`/`for_each` patterns on `module` blocks:

```hcl
# 1
module "bastion" {
  count  = var.environment == "dev" ? 0 : 1
  source = "./modules/bastion"

  vpc_id           = var.vpc_id
  public_subnet_id = var.public_subnet_ids[0]
}

# 2
output "bastion_dns" {
  value = length(module.bastion) > 0 ? module.bastion[0].dns_name : null
}
```

- **`# 1`** — Don't create the bastion in dev (the team uses VPN); create it in staging/prod.
- **`# 2`** — `length(module.bastion) > 0` is more readable than `count > 0` for the consumer.

## 22.5 Cascading defaults with `coalesce()`, `lookup()`, and `try()`

> **📚 Background:** Real configurations have layered defaults — an organization default, a region default, an environment default, an explicit override. Plain ternaries (`a != null ? a : b`) work for two-tier, but get unwieldy for four. Terraform's "give me the first non-null/non-empty value" functions are how you express this cleanly.

```hcl
locals {
  # 1 — coalesce returns the first non-null argument
  resolved_instance_type = coalesce(
    var.instance_type,                                        # explicit override
    var.environment_defaults[var.environment].instance_type,  # env default
    var.region_defaults[var.region].instance_type,            # region default
    "t3.medium",                                              # global fallback
  )

  # 2 — coalescelist returns the first non-empty list
  resolved_subnet_ids = coalescelist(
    var.private_subnet_ids,
    var.default_subnet_ids,
  )

  # 3 — lookup with a default for missing keys
  cidr_for_region = lookup(var.region_cidrs, var.region, "10.0.0.0/16")

  # 4 — nested lookups with try() (much cleaner than ternaries)
  log_retention = try(
    var.overrides.logging.retention_days,
    var.environment_defaults[var.environment].log_retention_days,
    30,
  )
}
```

**Line-by-line:**

- **`# 1`** — `coalesce(a, b, c, d)` returns the *first non-null* argument. Errors if all arguments are null.
- **`# 2`** — `coalescelist` is the list version: first non-empty list. Useful for "use these subnets if provided, otherwise fall back to defaults."
- **`# 3`** — `lookup(map, key, default)` is like `map[key]` but returns the default if the key is missing instead of erroring.
- **`# 4`** — `try(a, b, c)` evaluates each argument in order and returns the first one that doesn't raise an error. Different from `coalesce` — `try` handles *errors* (like missing object attributes), whereas `coalesce` handles *null values*.

> **⚠️ Gotcha:** `coalesce()` is happy with empty strings and empty lists — those count as "present." If you want "non-null AND non-empty," use `try()` carefully or write an explicit conditional.

> **🔗 References:**
> - `coalesce` — https://developer.hashicorp.com/terraform/language/functions/coalesce
> - `coalescelist` — https://developer.hashicorp.com/terraform/language/functions/coalescelist
> - `lookup` — https://developer.hashicorp.com/terraform/language/functions/lookup
> - `try` — https://developer.hashicorp.com/terraform/language/functions/try

## 22.6 `try()` and `can()` — handling errors in expressions

> **📚 Background:** These two functions are Terraform's closest thing to `try`/`catch`. They let you write expressions that might fail and recover gracefully — typically when reading a deeply-nested attribute that may or may not exist in the input.

### `try()` — return the first non-error expression

```hcl
locals {
  # 1
  user_email = try(
    var.user.profile.email,
    var.user.email,
    "unknown@example.com",
  )

  # 2
  json_value = try(
    jsondecode(var.config_json),
    {},   # default to empty object if JSON is invalid
  )

  # 3 — combined with element access on possibly-empty lists
  first_subnet = try(var.subnet_ids[0], null)
}
```

**Line-by-line:**

- **`# 1`** — `try` evaluates `var.user.profile.email` first. If `profile` doesn't exist, that throws; `try` catches and moves to the next arg.
- **`# 2`** — `jsondecode` errors on invalid JSON; `try` returns an empty object instead.
- **`# 3`** — Safe indexing. If `var.subnet_ids` is empty, `var.subnet_ids[0]` errors; `try` returns null.

### `can()` — true/false for whether an expression would succeed

```hcl
locals {
  # 1
  is_valid_cidr = can(cidrhost(var.cidr_block, 0))

  # 2
  is_email = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.email))
}

# 3
variable "subnet_cidrs" {
  type = list(string)
  validation {
    condition     = alltrue([for c in var.subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All subnet CIDRs must be valid IPv4/IPv6 CIDR notation."
  }
}
```

**Line-by-line:**

- **`# 1`** — Returns `true` if `var.cidr_block` is a valid CIDR; `false` otherwise.
- **`# 2`** — Validate an email-shaped string via regex. Note: not full RFC 5322 validation, just a sanity check.
- **`# 3`** — `can()` shines inside `validation` blocks. The expression "for every CIDR, can we compute a host? If yes, it's valid" is much cleaner than parsing the string manually.

> **🔗 References:**
> - `try` — https://developer.hashicorp.com/terraform/language/functions/try
> - `can` — https://developer.hashicorp.com/terraform/language/functions/can

## 22.7 The `one()` function — safe single-element extraction

> **📚 Background:** When you use `count = condition ? 1 : 0`, accessing the resource via `[0]` errors when the resource doesn't exist. The `one()` function (Terraform 0.15+) extracts the single element from a one-element list, or returns `null` if the list is empty. It also errors loudly if the list has more than one element — so it's safer than `[0]`.

```hcl
# 1
resource "aws_eip" "nat" {
  count  = var.create_nat ? 1 : 0
  domain = "vpc"
}

# 2 — old style, error-prone
output "nat_eip_arn_old" {
  value = var.create_nat ? aws_eip.nat[0].arn : null
}

# 3 — new style with one()
output "nat_eip_arn_new" {
  value = try(one(aws_eip.nat).arn, null)
}

# 4 — even cleaner with one() inside try()
output "nat_eip_arn_cleanest" {
  value = one(aws_eip.nat[*].arn)
}
```

**Line-by-line:**

- **`# 1`** — Conditionally created EIP.
- **`# 2`** — Old conditional indexing. Works but you have to repeat the condition.
- **`# 3`** — `one()` returns the single object or null. Wrapped in `try` to handle the null safely (otherwise `null.arn` errors).
- **`# 4`** — The splat (`[*]`) turns the list of resources into a list of arns; `one()` extracts the single arn or returns null.

> **🔗 Reference:** `one` — https://developer.hashicorp.com/terraform/language/functions/one

## 22.8 Variable validation — fail fast at plan time

> **📚 Background:** Variable validation rules (Terraform 0.13+) check inputs at plan time and produce a clean error message. Much better than failing five minutes into an apply when the cloud rejects an invalid value. **Use validation aggressively — it's the cheapest form of error handling.**

```hcl
variable "environment" {
  type        = string
  description = "Environment name"

  # 1
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_count" {
  type    = number
  default = 3

  # 2
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "instance_count must be between 1 and 100."
  }

  # 3 — Terraform 1.9+ supports multiple validation blocks
  validation {
    condition     = floor(var.instance_count) == var.instance_count
    error_message = "instance_count must be a whole number."
  }
}

variable "ami_id" {
  type = string

  # 4
  validation {
    condition     = can(regex("^ami-[a-f0-9]{8,17}$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID (ami-...)."
  }
}

variable "db_password" {
  type      = string
  sensitive = true

  # 5
  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }

  validation {
    condition     = can(regex("[A-Z]", var.db_password)) && can(regex("[0-9]", var.db_password))
    error_message = "db_password must contain at least one uppercase letter and one digit."
  }
}

variable "tags" {
  type    = map(string)
  default = {}

  # 6
  validation {
    condition     = contains(keys(var.tags), "Owner") && contains(keys(var.tags), "CostCenter")
    error_message = "tags must include both 'Owner' and 'CostCenter' keys."
  }
}

# 7
variable "subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.subnet_cidrs) >= 2
    error_message = "Must provide at least 2 subnet CIDRs for HA."
  }

  validation {
    condition     = alltrue([for c in var.subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All subnet_cidrs must be valid CIDR notation."
  }

  validation {
    condition     = length(distinct(var.subnet_cidrs)) == length(var.subnet_cidrs)
    error_message = "subnet_cidrs must be unique (no duplicates)."
  }
}
```

**Line-by-line:**

- **`# 1`** — `contains(list, value)` membership check; the classic enum-style validation.
- **`# 2`** — Numeric range check.
- **`# 3`** — Whole-number check via `floor()`.
- **`# 4`** — Regex validation wrapped in `can()` so an invalid regex doesn't itself error.
- **`# 5`** — Password strength: multiple `validation` blocks each check one aspect. **All must pass.**
- **`# 6`** — Enforce mandatory tags. Useful for chargeback/governance.
- **`# 7`** — A combination: length, format, uniqueness. Each in a separate block produces a focused error message.

> **⚠️ Gotcha — what you CAN'T do in validation:**
>
> Validation conditions can only reference `var.<this_variable>` — not other variables, not data sources, not resources. This is by design (variables are evaluated before anything else). For cross-variable rules, use `precondition` blocks (§22.9).

> **🔗 Reference:** Custom validation — https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules

## 22.9 `precondition` and `postcondition` — assertions in resources

> **📚 Background:** `precondition` and `postcondition` (Terraform 1.2+) let you assert invariants tied to a specific resource or data source — checked at plan time (precondition) or after apply (postcondition). Unlike variable validation, they can reference other resources, data sources, and module outputs.

### `precondition` — check before creating/updating

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # 1
  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "Selected AMI must be x86_64, got ${self.architecture}."
    }
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # 2
  lifecycle {
    precondition {
      condition     = data.aws_subnet.selected.cidr_block != ""
      error_message = "The selected subnet must have a CIDR block."
    }

    # 3
    precondition {
      condition = contains(
        ["t3.micro", "t3.small", "t3.medium", "t3.large"],
        var.instance_type,
      )
      error_message = "instance_type ${var.instance_type} is not in the approved t3 family list."
    }

    # 4
    postcondition {
      condition     = self.private_ip != ""
      error_message = "Instance failed to get a private IP."
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — `postcondition` on a data source. `self` refers to the data source itself; we assert the resolved AMI is x86_64.
- **`# 2`** — `precondition` on a resource. Checked at plan time, before any change is applied.
- **`# 3`** — Multiple preconditions. All must pass. This one duplicates a variable validation, but here we could reference any external value.
- **`# 4`** — `postcondition` on a resource. Checked after the resource is created/updated. If it fails, apply fails *but the resource is still created* — you have to fix the underlying issue and re-apply.

### `precondition` referencing another resource

```hcl
resource "aws_iam_role" "ecs_task" {
  name = "${var.name}-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_ecs_task_definition" "app" {
  family             = var.name
  task_role_arn      = aws_iam_role.ecs_task.arn
  execution_role_arn = aws_iam_role.ecs_execution.arn

  # ... other config ...

  lifecycle {
    # 1
    precondition {
      condition     = aws_iam_role.ecs_task.arn != aws_iam_role.ecs_execution.arn
      error_message = "Task role and execution role must be different IAM roles."
    }
  }
}
```

- **`# 1`** — A precondition that references *other* resources. This catches a common config mistake (using the same role for two distinct purposes) at plan time, before AWS rejects it at apply.

### Output-level preconditions

```hcl
output "alb_dns_name" {
  value = aws_lb.main.dns_name

  precondition {
    condition     = aws_lb.main.dns_name != ""
    error_message = "ALB has no DNS name; something went wrong."
  }
}
```

> **🔗 Reference:** Custom conditions — https://developer.hashicorp.com/terraform/language/expressions/custom-conditions

## 22.10 `check` blocks — non-blocking assertions

> **📚 Background:** `check` blocks (Terraform 1.5+) are a way to assert ongoing invariants *without* failing apply. They run during plan and after apply; failures are reported as warnings, not errors. Use them to surface drift or unexpected conditions without blocking deployment.

```hcl
# 1
check "https_redirect_works" {
  data "http" "site" {
    url = "https://${aws_lb.main.dns_name}/healthz"
  }

  assert {
    condition     = data.http.site.status_code == 200
    error_message = "Health check returned ${data.http.site.status_code}, expected 200."
  }
}

# 2
check "all_subnets_have_route_to_nat" {
  assert {
    condition = alltrue([
      for s in module.vpc.private_subnets : s != ""
    ])
    error_message = "Not all private subnets exist."
  }
}

# 3
check "rds_backup_retention_is_reasonable" {
  assert {
    condition     = aws_db_instance.main.backup_retention_period >= 7
    error_message = "Backup retention is only ${aws_db_instance.main.backup_retention_period} days; recommended >= 7."
  }
}
```

**Line-by-line:**

- **`# 1`** — A check that runs an HTTP request against the live LB and asserts a 200. Embedded data sources inside `check` blocks are only evaluated when the check runs.
- **`# 2`** — Structural check: all private subnets exist.
- **`# 3`** — Best-practice check: warn if RDS backup retention is too low.

Output:

```
│ Warning: Check block assertion failed
│ Backup retention is only 3 days; recommended >= 7.
```

Apply still succeeds — but the team sees the warning in CI output and can address it.

> **🔗 Reference:** Checks — https://developer.hashicorp.com/terraform/language/checks

## 22.11 Optional object attributes — graceful schemas

```hcl
# 1
variable "subnet_config" {
  type = object({
    cidr             = string
    az               = string
    public           = optional(bool, false)
    nat_gateway      = optional(bool, false)
    nacl_rules       = optional(list(object({
      rule_number = number
      protocol    = string
      action      = string
      cidr        = string
      from_port   = optional(number, 0)
      to_port     = optional(number, 0)
    })), [])
  })
}
```

**Notes:**

- **`# 1`** — `optional(type)` makes a field optional and defaults to null. `optional(type, default)` makes it optional with a specific default. Nested optionals work.

This is far cleaner than building one massive object with many `null` values, or splitting into many small variables.

> **🔗 Reference:** Optional object type attributes — https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes

## 22.12 Provisioner error handling

> **⚠️ Gotcha:** Provisioners (`local-exec`, `remote-exec`, `file`) are Terraform's escape hatch for "do this thing the providers can't." HashiCorp explicitly recommends [using them as a last resort](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax). When you must, here's how to handle their failures gracefully.

```hcl
resource "aws_instance" "web" {
  # ...

  # 1
  provisioner "local-exec" {
    command = "echo Instance ${self.id} created"

    # 2
    on_failure = continue
  }

  # 3
  provisioner "local-exec" {
    when    = destroy
    command = "echo Instance ${self.id} destroyed"

    on_failure = continue
  }

  # 4
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/id_ed25519")
      timeout     = "2m"
    }
  }
}
```

**Line-by-line:**

- **`# 1`** — `local-exec` runs on the machine doing the apply.
- **`# 2`** — `on_failure = continue` ignores provisioner failure and lets apply continue. The default is `fail`, which taints the resource and fails the apply.
- **`# 3`** — A "destroy-time" provisioner. Runs when the resource is being destroyed. Has access to `self` for the resource being torn down.
- **`# 4`** — `remote-exec` SSHes in and runs commands. Provides `timeout` for the connection itself.

**Alternatives to provisioners (preferred):**

- **EC2 `user_data`** — cloud-init script that runs on first boot.
- **Packer** — build pre-configured AMIs.
- **Ansible** — separate config-management stage (see §16).
- **`null_resource` + `triggers`** — re-run external commands when inputs change.

## 22.13 Error handling in CI — exit codes

> **📚 Background:** Terraform's CLI returns specific exit codes that CI can act on. Use these to make pipelines smart.

```bash
# 1
terraform plan -detailed-exitcode -out=plan.tfplan
case $? in
  0) echo "No changes."         ;;
  1) echo "Error during plan."; exit 1 ;;
  2) echo "Changes detected."   ;;
esac

# 2
terraform apply plan.tfplan
if [ $? -ne 0 ]; then
  echo "Apply failed; sending alert"
  ./scripts/alert.sh "$JOB_URL"
  exit 1
fi
```

**Line-by-line:**

- **`# 1`** — `-detailed-exitcode` makes plan return:
  - `0` — succeeded, no changes
  - `1` — error
  - `2` — succeeded, has changes

  This is invaluable for **scheduled drift detection**: run plan nightly; on exit 2, alert.

- **`# 2`** — Apply returns 0 on success, non-zero on failure.

### Atlantis / scheduled drift detection example

```yaml
# .github/workflows/drift-detection.yml
name: Daily drift check
on:
  schedule:
    - cron: '0 6 * * *'   # daily at 06:00 UTC

jobs:
  drift:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111122223333:role/GHA-ReadOnly
          aws-region: eu-west-1
      - name: Check for drift in every module
        run: |
          set +e
          drift_found=0
          for dir in $(find live/prod -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" -exec dirname {} \;); do
            pushd "$dir" > /dev/null
            terragrunt plan -detailed-exitcode -lock=false -no-color > /tmp/plan.txt 2>&1
            ec=$?
            if [ "$ec" = "2" ]; then
              drift_found=1
              echo "::warning::Drift detected in $dir"
              cat /tmp/plan.txt | tail -50
            elif [ "$ec" != "0" ]; then
              echo "::error::Plan failed in $dir"
              cat /tmp/plan.txt | tail -50
            fi
            popd > /dev/null
          done
          exit $drift_found
```

This loops over every Terragrunt module, runs plan with `-detailed-exitcode`, and flags drift as a GitHub warning.

## 22.14 Recovering from partial apply failures

> **📚 Background:** Sometimes apply fails halfway through — some resources created, others not. Terraform leaves the state in a partial (but consistent) form. Recovery steps depend on what failed.

### Scenario 1: provider/network transient error

Just re-run apply. Terraform reads state, sees what's already created, and continues from there. **This is the normal recovery path; it's safe.**

### Scenario 2: a resource is "tainted" (creation partially succeeded)

```bash
# Check for tainted resources
terraform state list | xargs -I{} terraform state show {} | grep -B 1 tainted

# Force recreation of a tainted resource
terraform apply -replace=aws_instance.web
```

> **⚠️ Note:** `terraform taint` and `terraform untaint` are deprecated. Use `terraform apply -replace=<addr>` instead.

### Scenario 3: state was modified out of band

If someone (or something) deleted a resource in the cloud console:

```bash
terraform refresh                # update state from real world
terraform plan                   # see what's missing
terraform apply                  # recreate the missing resource
```

If a resource was *changed* in the console:

```bash
terraform plan                   # shows the drift
# Either:
terraform apply                  # restore Terraform's declared state
# Or:
# update your .tf code to match reality, then apply
```

### Scenario 4: state corruption (last resort)

If you suspect state corruption (e.g., disk full during write):

```bash
# 1 — backup current state
terraform state pull > corrupted.tfstate.json

# 2 — list previous versions in S3 (assumes versioned bucket)
aws s3api list-object-versions \
  --bucket mycompany-tf-state \
  --prefix path/to/terraform.tfstate

# 3 — download a good version
aws s3api get-object \
  --bucket mycompany-tf-state \
  --key path/to/terraform.tfstate \
  --version-id <previous-version-id> \
  good.tfstate

# 4 — push it (DANGEROUS; verify first)
terraform state push good.tfstate
```

> **⚠️ Always backup state before manual manipulation.** Versioned S3 buckets (see §5.3) save you here.

## 22.15 Conditional providers — when one cloud sometimes, another sometimes

Provider configuration itself can be conditional via aliases. Useful for multi-region or multi-account modules:

```hcl
# 1
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# 2
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# 3
resource "aws_s3_bucket" "primary_data" {
  provider = aws.primary
  bucket   = "${var.name}-primary"
}

# 4
resource "aws_s3_bucket" "dr_data" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = "${var.name}-dr"
}

# 5
resource "aws_s3_bucket_replication_configuration" "to_dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.primary

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.primary_data.id

  rule {
    id     = "to-dr"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.dr_data[0].arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

**Notes:**

- **`# 1`/`# 2`** — Two aliased providers.
- **`# 3`** — Always create the primary bucket.
- **`# 4`** — DR bucket only when enabled.
- **`# 5`** — Replication, configured on the *primary* provider but pointing at the DR bucket. Conditional on the same flag.

## 22.16 A complete error-handling-aware module example

Putting it all together — a module that uses every error-handling feature:

```hcl
# variables.tf
variable "name" {
  type        = string
  description = "Resource name prefix (3-30 chars, alphanumeric+hyphen)"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,29}$", var.name))
    error_message = "name must start with a letter, be 3-30 chars, lowercase alphanumeric + hyphen."
  }
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "config" {
  type = object({
    enable_logging    = optional(bool, true)
    enable_monitoring = optional(bool, true)
    log_retention     = optional(number, 30)
    custom_kms_key    = optional(string)
    tags              = optional(map(string), {})
  })
  default = {}

  validation {
    condition     = var.config.log_retention >= 1 && var.config.log_retention <= 365
    error_message = "log_retention must be between 1 and 365 days."
  }
}

variable "ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    sg_ids      = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.ingress_rules :
      (r.cidr_blocks != null && length(r.cidr_blocks) > 0) ||
      (r.sg_ids != null && length(r.sg_ids) > 0)
    ])
    error_message = "Each ingress rule must specify at least one of cidr_blocks or sg_ids."
  }

  validation {
    condition = alltrue([
      for r in var.ingress_rules :
      r.from_port >= 0 && r.to_port <= 65535 && r.from_port <= r.to_port
    ])
    error_message = "Each ingress rule must have valid port ranges (0-65535, from <= to)."
  }
}

# main.tf
locals {
  # Cascading defaults
  use_custom_kms = var.config.custom_kms_key != null
  kms_arn        = try(var.config.custom_kms_key, "alias/aws/s3")

  # Merge default tags
  tags = merge(
    {
      ManagedBy   = "terraform"
      Environment = var.environment
      Module      = "secure-bucket"
    },
    var.config.tags,
  )
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-${var.environment}"
  tags   = local.tags

  lifecycle {
    precondition {
      condition     = !local.use_custom_kms || can(regex("^arn:aws:kms:", var.config.custom_kms_key))
      error_message = "custom_kms_key must be a valid KMS ARN if provided."
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.use_custom_kms ? "aws:kms" : "AES256"
      kms_master_key_id = local.use_custom_kms ? local.kms_arn : null
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  count  = var.config.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = aws_s3_bucket.this.id   # log to itself (simple case)
  target_prefix = "access-logs/"
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  count               = var.config.enable_monitoring ? 1 : 0
  alarm_name          = "${var.name}-${var.environment}-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 100

  dimensions = {
    BucketName = aws_s3_bucket.this.id
  }
}

resource "aws_security_group" "bucket_access" {
  name        = "${var.name}-${var.environment}-access"
  description = "Network rules for accessing ${aws_s3_bucket.this.id}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.sg_ids
    }
  }
}

# Verify the configuration is actually safe
check "bucket_is_private" {
  data "aws_s3_bucket_public_access_block" "this" {
    bucket = aws_s3_bucket.this.id
  }

  assert {
    condition = (
      data.aws_s3_bucket_public_access_block.this.block_public_acls &&
      data.aws_s3_bucket_public_access_block.this.block_public_policy
    )
    error_message = "Bucket ${aws_s3_bucket.this.id} is not properly locked down."
  }
}

# outputs.tf
output "bucket_arn" {
  value = aws_s3_bucket.this.arn

  precondition {
    condition     = aws_s3_bucket.this.arn != ""
    error_message = "Bucket ARN is empty; creation may have failed."
  }
}

output "security_group_id" {
  value = length(var.ingress_rules) > 0 ? aws_security_group.bucket_access.id : null
}

output "alarm_arn" {
  value = try(one(aws_cloudwatch_metric_alarm.errors).arn, null)
}
```

This module demonstrates:

- **Input validation** with multiple `validation` blocks per variable.
- **Optional object attributes** with sensible defaults.
- **Conditional resource creation** with `count`.
- **Dynamic blocks** for variable-length lists.
- **`precondition`/`postcondition`** for cross-resource checks.
- **`check` blocks** for ongoing assertions.
- **`try()` and `one()`** for safe output access.
- **Cascading defaults** with `try()` and locals.

## 22.17 Summary — when to use what

| Need                                              | Use                                              |
| ------------------------------------------------- | ------------------------------------------------ |
| Validate a single variable                        | `validation` block on the `variable`             |
| Check an invariant across resources               | `lifecycle { precondition }`                     |
| Verify state after apply                          | `lifecycle { postcondition }`                    |
| Warn (not fail) about drift / suboptimal config   | `check` block                                    |
| Create resource conditionally                     | `count = condition ? 1 : 0`                      |
| Create N items where N may be 0                   | `for_each = filtered_map`                        |
| Include nested block conditionally                | `dynamic "block" { for_each = condition ? [1] : [] }` |
| Reference an attribute that may not exist         | `try(deeply.nested.attr, default)`               |
| Branch on whether an expression would error       | `can(expression)`                                |
| Safe single-element access from conditional resource | `one(resource[*].attr)`                       |
| Fallback through layered defaults                 | `coalesce(a, b, c, default)`                     |
| Handle missing map keys                           | `lookup(map, key, default)`                      |
| Optional input fields                             | `optional(type, default)` in object types        |
| CI knows whether plan had changes                 | `terraform plan -detailed-exitcode`              |
| Recover from partial apply                        | Re-run; or `terraform apply -replace=<addr>`     |
| Recover from state corruption                     | Restore from versioned backend                   |

These primitives compose. A production-quality module typically uses 4-6 of them at once.

> **🔗 References (consolidated):**
> - Custom validation — https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules
> - Custom conditions (precondition / postcondition) — https://developer.hashicorp.com/terraform/language/expressions/custom-conditions
> - Checks — https://developer.hashicorp.com/terraform/language/checks
> - Dynamic blocks — https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
> - Conditional expressions — https://developer.hashicorp.com/terraform/language/expressions/conditionals
> - Functions reference — https://developer.hashicorp.com/terraform/language/functions
> - Provisioners (use sparingly) — https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
> - CLI exit codes — https://developer.hashicorp.com/terraform/cli/commands/plan#detailed-exitcode

---

# 23. Appendices

## 23.1 Glossary

- **Apply** — execute the plan; mutate the world.
- **Backend** — where state is stored (S3, Azure Storage, GCS, Terraform Cloud, …).
- **CRD** — Custom Resource Definition; how Kubernetes is extended.
- **Drift** — actual state differs from declared state.
- **HCL** — HashiCorp Configuration Language; what Terraform/Terragrunt files are written in.
- **IaC** — Infrastructure as Code.
- **IRSA** — IAM Roles for Service Accounts (EKS); maps a K8s service account to an IAM role.
- **Module** — a reusable, parameterized collection of Terraform configuration.
- **OIDC** — OpenID Connect; used here for keyless CI → cloud authentication.
- **OpenTofu** — open-source fork of Terraform (post-BSL relicense in 2023).
- **Plan** — diff between declared and actual; what would be done.
- **Provider** — plugin that talks to one API (AWS, Azure, K8s, …).
- **Resource** — one declared piece of infrastructure.
- **State** — the JSON file mapping declared resources to real-world IDs.
- **STS** — AWS Security Token Service; issues short-lived credentials.
- **Workspace** — separate state file for the same Terraform code (avoid for environments).

## 23.2 Cheat sheet of the most-used commands

```bash
# === Terraform ===

# Setup
terraform init                                # download providers, configure backend
terraform init -upgrade                       # bump providers within constraints
terraform init -reconfigure                   # change backend (don't migrate)
terraform init -migrate-state                 # change backend AND copy state

# Code quality
terraform fmt -recursive                      # auto-format all .tf files
terraform validate                            # syntax/config check
terraform test                                # run *.tftest.hcl files

# The hot loop
terraform plan                                # show diff
terraform plan -out=plan.tfplan               # save plan
terraform apply plan.tfplan                   # apply saved plan
terraform apply -auto-approve                 # CI mode (no prompt)

# Inspection
terraform show                                # pretty-print current state
terraform show -json | jq                     # machine-readable state
terraform output                              # all outputs
terraform output [-raw] [name]                # one output (-raw for scripting)
terraform state list                          # list all resources
terraform state show <addr>                   # one resource in detail
terraform graph | dot -Tsvg > graph.svg       # dependency graph (needs graphviz)
terraform console                             # REPL — try expressions interactively

# Modifications to state
terraform state mv <src> <dst>                # rename
terraform state rm <addr>                     # remove from state without destroying
terraform import <addr> <id>                  # import existing resource
terraform refresh                             # update state from real world
terraform force-unlock <LOCK_ID>              # break a stuck lock

# Teardown
terraform plan -destroy                       # what would be destroyed
terraform destroy                             # destroy after y/n prompt

# Debugging
TF_LOG=DEBUG terraform apply
TF_LOG=TRACE terraform apply 2> tf.log

# === Terragrunt ===

# Single module — like terraform but smarter
terragrunt init
terragrunt plan
terragrunt apply
terragrunt destroy
terragrunt output

# Code quality
terragrunt hclfmt                             # format terragrunt.hcl files
terragrunt validate-inputs                    # check inputs match module variables

# Multi-module (the killer feature)
terragrunt run --all plan                     # newer syntax (0.60+)
terragrunt run-all plan                       # older syntax (still supported)
terragrunt run --all apply --non-interactive
terragrunt run --all destroy --non-interactive
terragrunt run --all apply --queue-include-dir=eks  # only specific dirs (+ deps)

# Inspection
terragrunt graph-dependencies | dot -Tsvg > deps.svg

# Debugging
terragrunt --log-level debug apply
terragrunt --log-level trace apply
```

## 23.3 Recommended further reading

### Books

- **[Terraform: Up & Running](https://www.terraformupandrunning.com/)** by Yevgeniy Brikman — the canonical practical guide; covers Terragrunt extensively.
- **[Designing Data-Intensive Applications](https://dataintensive.net/)** by Martin Kleppmann — foundational background for everything in §17 (Kafka, NiFi, OpenSearch).
- **[Site Reliability Engineering](https://sre.google/sre-book/)** (free online) — Google's playbook.
- **[Observability Engineering](https://www.oreilly.com/library/view/observability-engineering/9781492076438/)** by Majors / Fong-Jones / Miranda — the modern observability bible.

### Documentation

- **Terraform** — https://developer.hashicorp.com/terraform/docs
- **OpenTofu** — https://opentofu.org/docs/
- **Terragrunt** — https://terragrunt.gruntwork.io/docs/
- **Terraform Registry** — https://registry.terraform.io/
- **terraform-aws-modules** — https://github.com/terraform-aws-modules
- **terraform-google-modules** — https://github.com/terraform-google-modules
- **AWS Well-Architected** — https://aws.amazon.com/architecture/well-architected/
- **Azure Architecture Center** — https://learn.microsoft.com/en-us/azure/architecture/

### Tooling

- **tflint** — https://github.com/terraform-linters/tflint
- **tfsec** — https://aquasecurity.github.io/tfsec/
- **Checkov** — https://www.checkov.io/
- **terraform-docs** — https://terraform-docs.io/
- **pre-commit-terraform** — https://github.com/antonbabenko/pre-commit-terraform
- **Terratest** — https://terratest.gruntwork.io/
- **Infracost** — https://www.infracost.io/

### Community

- **Gruntwork blog** — https://blog.gruntwork.io/
- **HashiCorp blog** — https://www.hashicorp.com/blog
- **r/Terraform** — https://www.reddit.com/r/Terraform/
- **The CNCF landscape** — https://landscape.cncf.io/

## 23.4 A complete skeleton repo to copy

```
infrastructure/
├── .github/workflows/
│   └── terragrunt.yml
├── .gitignore
├── .pre-commit-config.yaml
├── .terraform-version
├── .terragrunt-version
├── README.md
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── README.md
│   │   └── examples/basic/
│   ├── eks/
│   ├── eks-addons/
│   ├── ecs-service/
│   ├── rds-postgres/
│   ├── s3-bucket/
│   ├── msk/
│   ├── opensearch/
│   ├── kafka-strimzi/         # K8s-based
│   ├── nifi/
│   ├── observability/         # kube-prometheus-stack + OTel + Tempo + Loki
│   └── alb/
│
├── live/
│   ├── terragrunt.hcl
│   ├── _envcommon/
│   │   ├── vpc.hcl
│   │   ├── eks.hcl
│   │   └── ...
│   │
│   ├── prod/
│   │   ├── account.hcl
│   │   ├── env.hcl
│   │   └── eu-west-1/
│   │       ├── region.hcl
│   │       ├── 10-network/
│   │       │   └── terragrunt.hcl
│   │       ├── 20-shared/
│   │       ├── 30-eks/
│   │       ├── 31-eks-addons/
│   │       ├── 40-msk/
│   │       ├── 41-opensearch/
│   │       ├── 50-observability/
│   │       ├── 60-nifi/
│   │       └── 70-apps/
│   │           ├── ingestion/
│   │           └── api/
│   │
│   ├── staging/
│   └── dev/
│
└── policies/
    ├── opa/
    │   └── *.rego
    └── checkov/
        └── checkov.yml
```

Every leaf `terragrunt.hcl` is ~10 lines. All the heavy lifting lives in versioned modules. Promoting through environments is changing one `?ref=` per PR.

## 23.5 A 90-day adoption plan

### Days 1-14: Foundations

- [ ] Pick Terraform vs OpenTofu (default: OpenTofu for new orgs in 2026; Terraform for existing investments).
- [ ] Create state bucket + lock table (or Azure Storage account).
- [ ] Set up the repo skeleton above.
- [ ] Wire up CI with OIDC.
- [ ] First module: `vpc`. Deploy to dev.

### Days 15-30: Shared services

- [ ] Modules: IAM baselines, DNS zones, ACM certs.
- [ ] Pre-commit + Checkov + tfsec in CI.
- [ ] Onboarding doc.
- [ ] Designate module owners.

### Days 31-60: Compute platform

- [ ] EKS or ECS module + add-ons.
- [ ] Observability stack (Prometheus, Grafana, OTel).
- [ ] First real application deployed end-to-end.
- [ ] Document promotion workflow (dev → staging → prod).

### Days 61-90: Data and resilience

- [ ] RDS, MSK (or self-hosted Kafka), OpenSearch.
- [ ] Multi-AZ verified; documented restore drills.
- [ ] Promote dev → staging → prod with same code.
- [ ] Scheduled drift detection.
- [ ] First chaos test.

After 90 days you'll have a layered, versioned, auditable platform. The remaining work is **organizational** — module ownership, on-call rotations, deprecation policy, cost reviews. The technology is the easy part.

---

# Conclusion

Terraform and Terragrunt are not magic. They are bookkeeping tools that let humans collaborate on infrastructure without stepping on each other and without forgetting what they built. Used well, they give you:

- A complete, version-controlled, peer-reviewed record of every piece of cloud you own.
- The ability to rebuild your platform in a new region or account in hours, not weeks.
- Confidence that staging mirrors prod, that disaster recovery works, and that nothing was provisioned by someone who has since left.

### The patterns that matter most

1. **Layered architecture** (network → platform → app) with **separate state per layer**.
2. **Versioned shared modules** in their own repo, consumed by `live/` configs with `?ref=<tag>`.
3. **Terragrunt for DRY config** across environments and the dependency graph between layers.
4. **CI as the only path to prod** — never apply from a laptop.
5. **Policy as code** — Checkov, OPA, Sentinel in the PR pipeline.
6. **Multi-AZ by default; multi-region when the business case requires it.**
7. **Observability provisioned alongside the workloads it monitors.**
8. **Documentation, ownership, runbooks** — the tech only works if the organization around it does.

### Final advice

- **Start small.** A `vpc` module in dev with a remote backend is enough on day one.
- **Iterate.** Don't try to design the perfect platform up front. Layer it on as needs arise.
- **Read other people's modules.** [terraform-aws-modules](https://github.com/terraform-aws-modules) is an education in itself.
- **Embrace the plan.** The whole value proposition is "see the change before it happens." Use it.
- **Talk to your team.** The hardest problems in IaC are organizational, not technical.

Now go `terraform init`. Good luck.

---

*This tutorial was written to give a complete picture from absolute beginner to operating a production multi-cloud platform. For corrections, improvements, or questions, the canonical sources linked throughout (HashiCorp docs, Gruntwork docs, the Terraform Registry, CNCF project docs) are kept far more up-to-date than any standalone document could be. When in doubt, check them.*
