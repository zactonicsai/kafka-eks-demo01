# Kafka on EKS — Terraform + GitHub CI/CD + Local Observability Stack

A simple, secure, end-to-end example that:

1. **Provisions Kafka on AWS EKS** with Terraform (VPC, EKS, Strimzi-managed
   Kafka, Prometheus + Grafana).
2. **Deploys via a GitHub Actions pipeline** using OIDC (no stored AWS keys),
   with `tfsec` + `Checkov` security scanning and a manual approval gate.
3. **Runs a full local stack** with Docker Compose: Kafka, a Python producer
   and consumer, an OpenTelemetry Collector, Prometheus, and a Grafana
   dashboard that tracks messages produced/consumed and end-to-end latency.

Every pipeline step and every Kafka/monitoring config line is commented.

---

## Repository layout

```
.
├── .github/workflows/terraform.yml   # CI/CD pipeline (fully commented)
├── terraform/                        # Infrastructure as Code
│   ├── versions.tf                   # providers + S3 remote state backend
│   ├── main.tf                       # wires modules together
│   ├── variables.tf / outputs.tf
│   └── modules/
│       ├── vpc/                       # private/public subnets, NAT, routing
│       ├── eks/                       # EKS + KMS secret encryption + IRSA
│       ├── kafka/                     # Strimzi operator + Kafka (TLS+SCRAM)
│       └── monitoring/               # kube-prometheus-stack + PodMonitor
├── local/                            # Docker Compose dev + observability
│   ├── docker-compose.yml
│   ├── producer/                      # Python producer (OTEL instrumented)
│   ├── consumer/                      # Python consumer (OTEL + latency)
│   ├── kafka/kafka-jmx.yml            # JMX -> Prometheus rules
│   └── monitoring/
│       ├── prometheus/prometheus.yml
│       ├── otel-collector-config.yaml
│       └── grafana/                   # auto-provisioned datasource + dashboard
└── docs/AWS_OIDC_SETUP.md            # one-time AWS bootstrap for the pipeline
```

---

## Part A — Try it locally first (5 minutes)

This needs only Docker. It is the fastest way to see messages flowing and the
Grafana dashboard updating.

```bash
cd local
docker compose up --build
```

Then open:

| Service     | URL                     | Login         |
|-------------|-------------------------|---------------|
| Grafana     | http://localhost:3000   | `admin`/`admin` |
| Prometheus  | http://localhost:9090   | —             |

In Grafana, open the **Kafka → Kafka Message Tracking** dashboard. You'll see:
- total messages produced/consumed,
- produced-vs-consumed rate,
- broker messages-in per topic,
- bytes in/out,
- p95 produce→consume latency.

The producer sends one JSON message per second to the `demo-messages` topic;
the consumer reads them and records latency. Both push OTEL metrics/traces to
the OpenTelemetry Collector, which Prometheus scrapes.

Tear down with `docker compose down -v`.

### How the local monitoring fits together

```
producer ─┐                         ┌─> Prometheus ─> Grafana
          ├─ OTLP/gRPC ─> OTEL Collector (re-exposes /metrics on :8889)
consumer ─┘
kafka ─ JMX ─> jmx-exporter (:5556) ─> Prometheus ─> Grafana
```

---

## Part B — Deploy to AWS EKS

### Prerequisites
- An AWS account, `awscli`, `kubectl`, and Terraform ≥ 1.6 (only if applying
  locally; the pipeline installs its own).
- Complete the **one-time bootstrap** in [`docs/AWS_OIDC_SETUP.md`](docs/AWS_OIDC_SETUP.md):
  create the OIDC provider, the CI IAM role, the GitHub secrets, and the S3 +
  DynamoDB state backend.

### Option 1 — via the GitHub pipeline (recommended)
1. Update the `backend "s3"` block in `terraform/versions.tf` with your bucket
   and lock-table names.
2. Add repo secrets `AWS_OIDC_ROLE_ARN` and `GRAFANA_ADMIN_PASSWORD`.
3. Open a PR → the **plan** job runs (fmt, validate, tfsec, Checkov, plan).
4. Merge to `main` → the **apply** job runs after approval in the `production`
   GitHub Environment.

### Option 2 — apply locally
```bash
cd terraform
export TF_VAR_grafana_admin_password="a-strong-password"
terraform init
terraform plan
terraform apply
```

### After apply
```bash
# Configure kubectl (command is also a Terraform output).
aws eks update-kubeconfig --region us-east-1 --name demo-kafka

# Watch Kafka come up.
kubectl -n kafka get pods

# Reach Grafana in the cluster.
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# open http://localhost:3000  (user: admin, password: the secret you set)
```

---

## Security choices (best practices)

**Network**
- Kafka brokers and worker nodes run **only in private subnets**; no public IPs.
- Outbound internet via NAT gateways; no inbound from the internet.

**EKS**
- Kubernetes Secrets are **envelope-encrypted with a dedicated KMS key** (auto-rotating).
- All control-plane logs (api, audit, authenticator, controllerManager, scheduler)
  go to CloudWatch.
- **IRSA** (OIDC) enabled so pods get scoped IAM roles instead of node-wide creds.
- Public API endpoint is enabled for CI but should be locked to your CIDR
  (`public_access_cidrs` in `modules/eks/main.tf`).

**Kafka (Strimzi)**
- **TLS encryption** on the broker listener.
- **SCRAM-SHA-512 authentication**.
- `min.insync.replicas = 2` with replication factor 3 for durability.
- Namespace runs under the **restricted Pod Security Standard**.

**Pipeline**
- **OIDC federation** — zero long-lived AWS keys in GitHub.
- Least-privilege job `permissions`.
- **tfsec** and **Checkov** scans block insecure IaC before apply.
- Apply uses the exact reviewed plan artifact and a protected environment.

**Containers**
- Python images run as a **non-root user** on a slim base.

> Note on local vs cloud: the local Compose stack uses PLAINTEXT Kafka and
> `admin/admin` Grafana **for convenience only**. The cloud stack uses TLS +
> SCRAM and a secret-injected Grafana password. Never use the local defaults
> for anything internet-facing.

---

## Customizing

| Want to change            | Where                                             |
|---------------------------|---------------------------------------------------|
| Region / name prefix      | `terraform/variables.tf`                          |
| Node size / count         | `terraform/modules/eks/variables.tf`              |
| Kafka brokers / version   | `terraform/modules/kafka/variables.tf`            |
| Broker metrics rules      | `terraform/modules/kafka/manifests/*-configmap.yaml` |
| Local topic / rate        | `local/docker-compose.yml`, `local/producer/producer.py` |
| Dashboard panels          | `local/monitoring/grafana/dashboards/kafka-dashboard.json` |

---

## Cleanup

Local: `cd local && docker compose down -v`

Cloud: `cd terraform && terraform destroy`
(then optionally remove the bootstrap S3 bucket, DynamoDB table, OIDC provider,
and IAM role.)
"# kafka-eks-demo01" 
