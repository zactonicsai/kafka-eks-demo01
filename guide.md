# Running Apache Kafka on Amazon EKS — Technical Guide

**Technical Guide · v1.0**

This guide explains, in plain language, how this project builds a message-streaming system in the cloud and watches over it. We start with the big picture, then look inside each piece: the infrastructure code (Terraform), the cluster (EKS), the message system (Kafka), and the monitoring (Prometheus, Grafana, and OpenTelemetry).

> **Who is this for?** An admin or platform team that needs to run, understand, and keep a Kafka system healthy — even if they are new to some of these tools. No prior Kafka or Kubernetes knowledge is assumed.

**At a glance:**

- **4** layers: network, cluster, Kafka, monitoring
- **100%** built as code — repeatable and reviewable
- **3×** broker replicas for fault tolerance

-----

## Contents

1. [The big picture (a simple analogy)](#1-the-big-picture-a-simple-analogy)
1. [Terraform: building infrastructure as code](#2-terraform-building-infrastructure-as-code)
1. [Amazon EKS: the cluster setup](#3-amazon-eks-the-cluster-setup)
1. [Security concerns & mitigations](#4-security-concerns--mitigations)
1. [How Apache Kafka works](#5-how-apache-kafka-works)
1. [Fault tolerance & high availability](#6-fault-tolerance--high-availability)
1. [Monitoring: OpenTelemetry, Prometheus & Grafana](#7-monitoring-opentelemetry-prometheus--grafana)
1. [Example Prometheus (PromQL) queries](#8-example-prometheus-promql-queries)
1. [Simple use cases for an admin team](#9-simple-use-cases-for-an-admin-team)
1. [Getting started, step by step](#10-getting-started-step-by-step)
1. [References & official docs](#11-references--official-docs)

-----

## 1. The big picture (a simple analogy)

Imagine a busy post office. People drop off letters, and other people pick them up. The post office does not force the sender and receiver to be in the same room at the same time — it holds the letters safely until the receiver is ready. That is exactly what **Apache Kafka** does, but for digital messages between computer programs.

|The analogy             |The real thing          |What it is                                                                                                       |
|------------------------|------------------------|-----------------------------------------------------------------------------------------------------------------|
|The post office building|**Amazon EKS**          |A managed Kubernetes service — the building and staff that keep everything running. Kafka lives inside it.       |
|The blueprint           |**Terraform**           |Written instructions that build the whole post office automatically, the same way every time, instead of by hand.|
|The security cameras    |**Prometheus & Grafana**|They record what is happening and show it on dashboards so you can spot trouble early.                           |
|The tracking labels     |**OpenTelemetry (OTEL)**|Tags each message so you can follow its journey from sender to receiver.                                         |

The rest of this guide opens up each of these four pieces, one at a time.

> ℹ️ **Why use a streaming system?** Without a system like Kafka, every program would have to talk directly to every other program. If one is slow or offline, messages get lost. Kafka acts as a reliable buffer in the middle, so senders and receivers do not depend on each other being available at the same instant. This is called *decoupling*.

-----

## 2. Terraform: building infrastructure as code

**Terraform** is a tool that lets you describe cloud resources in text files. Instead of clicking buttons in the AWS website to create a network, a cluster, and servers, you write what you want, and Terraform makes it real. This is called *Infrastructure as Code*.

> ℹ️ **Infrastructure as Code (IaC):** Instead of manually clicking in a cloud console (which is easy to get wrong and impossible to repeat exactly), you describe your infrastructure in text files. Those files can be saved in Git, reviewed by teammates, and replayed to rebuild everything identically. If a server is destroyed, you re-run the code and it comes back the same.

### 2.1 Why this matters

- **Repeatable:** you get the exact same setup every time, in test and in production.
- **Reviewable:** changes go through a pull request, so a teammate can check them before they go live.
- **Reversible:** one command can tear the whole thing down so you stop paying for it.

### 2.2 How Terraform works internally (step by step)

Terraform follows a simple loop. Understanding it removes most of the mystery.

1. **Write** — You write `.tf` files describing the *desired state* (what you want to exist).
1. **Init** — `terraform init` downloads the *providers* — plugins that know how to talk to AWS, Kubernetes, and Helm.
1. **Plan** — `terraform plan` compares your desired state against the *current state* and shows exactly what it will add, change, or destroy. Nothing happens yet.
1. **Apply** — `terraform apply` makes the changes by calling the cloud APIs in the right order.
1. **State** — Terraform records what it built in a *state file*, so next time it knows what already exists.

> ℹ️ **What is the state file?** Terraform needs to remember what it already created so it does not make duplicates. It writes this memory into a state file, which maps your code to the real resources (their IDs, IPs, etc.). It can contain sensitive values, which is why it is stored encrypted in S3 and never committed to Git.

### 2.3 The dependency graph

Terraform reads all your files and builds a **graph** — a map of what depends on what. For example, the Kafka cluster cannot exist before the EKS cluster, and EKS cannot exist before the network. Terraform works out this order on its own from how resources reference each other, and you can nudge it with `depends_on` when needed. It then creates independent things in parallel to save time.

### 2.4 How this project is organized (modules)

A **module** is a reusable folder of Terraform code. This project splits the work into four modules so each piece is small and understandable:

|Module      |What it builds                                     |
|------------|---------------------------------------------------|
|`vpc`       |The private network: subnets, routing, NAT gateways|
|`eks`       |The Kubernetes cluster and its worker machines     |
|`kafka`     |The Strimzi operator and the Kafka cluster itself  |
|`monitoring`|Prometheus, Grafana, and the metric scrapers       |

### 2.5 Remote state and locking

The state file is stored in an **Amazon S3 bucket** (not on your laptop) so the whole team shares one source of truth. To stop two people from changing things at the same time and corrupting it, Terraform uses **S3-native locking** (a small lock file). Newer Terraform versions do this without needing a separate DynamoDB table.

```hcl
# versions.tf — where the shared state lives
backend "s3" {
  bucket       = "my-tfstate-bucket"
  key          = "kafka-eks/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true        # state is encrypted at rest
  use_lockfile = true        # S3-native lock, no DynamoDB
}
```

> ℹ️ **Why locking matters:** If two engineers run `terraform apply` at the same moment, they could both edit the state file and corrupt it. A lock ensures only one change happens at a time — the second person simply waits. Modern Terraform does this with a tiny lock object in the same S3 bucket, so no extra database is needed.

**References:** [Terraform documentation](https://developer.hashicorp.com/terraform/docs) · [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)

-----

## 3. Amazon EKS: the cluster setup

**Kubernetes** is a system that runs and manages many small programs (called *containers*) across many machines. **Amazon EKS** (Elastic Kubernetes Service) is Amazon running the hardest, most error-prone part of Kubernetes — the “control plane” — for you, so your team can focus on your applications.

> ℹ️ **What is Kubernetes?** Kubernetes (“K8s”) is software that runs your applications inside containers across a fleet of machines. You tell it “I want 3 copies of this app running,” and it makes sure 3 are always running — restarting any that crash and moving them if a machine dies. EKS is Amazon running the control part of Kubernetes for you.

### 3.1 The two halves of a cluster

- **Control plane (AWS-managed):** The “brain.” It decides where programs run and keeps the desired number alive. AWS runs and patches this for you across multiple data centers.
- **Worker nodes (your machines):** The “muscle.” These are EC2 virtual machines where your containers (including Kafka brokers) actually run. This project uses a *managed node group* of 3–5 nodes.

### 3.2 What the EKS module sets up

- An EKS control plane on a recent Kubernetes version.
- A managed node group whose machines live **only in private subnets** (no direct internet address).
- A **KMS key** that encrypts Kubernetes secrets.
- Control-plane **audit logs** sent to CloudWatch.
- **IRSA** (IAM Roles for Service Accounts) so each app gets only the cloud permissions it needs.

> ℹ️ **IRSA — scoped permissions for pods:** IRSA lets each application get its *own* narrow set of AWS permissions, instead of every app sharing the broad permissions of the machine it runs on. If one app is compromised, the attacker only gets that app’s limited rights — not the keys to everything.

### 3.3 EKS best practices used here

- **Spread across Availability Zones.** Nodes run in three separate AWS data centers, so losing one zone does not take everything down.
- **Private worker nodes.** Workers have no public IP. They reach the internet only outbound, through a NAT gateway, never inbound.
- **Least-privilege node role.** The worker machines get only the three AWS policies they truly need to join the cluster and pull images.
- **Rolling updates.** When nodes are upgraded, only one is taken offline at a time, so the cluster keeps serving traffic.

**References:** [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) · [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

-----

## 4. Security concerns & mitigations

Security is not one feature; it is many small, careful choices. Below are the main risks and exactly how this project reduces each one.

|Concern                                |Mitigation                              |More detail       |
|---------------------------------------|----------------------------------------|------------------|
|Someone reaches Kafka from the internet|Brokers & nodes only in private subnets |Network isolation*|
|Messages read in transit               |TLS encryption on all Kafka listeners   |TLS*              |
|Unknown clients connect                |SCRAM-SHA-512 password authentication   |SCRAM auth*       |
|Secrets stolen from disk               |KMS envelope encryption of K8s secrets  |KMS*              |
|Leaked cloud credentials in CI         |GitHub OIDC — no stored AWS keys        |OIDC*             |
|Over-powerful pods                     |IRSA + restricted Pod Security Standard |Pod Security*     |
|Insecure infrastructure code merged    |tfsec + Checkov scans block the pipeline|Scanning*         |

*** More detail on each mitigation:**

- **Network isolation:** The Kafka brokers and worker machines are placed in private subnets. A private subnet has no route for inbound traffic from the internet. The machines can still reach out (to pull software updates) through a NAT gateway, but nobody on the internet can open a connection to them directly.
- **TLS encryption:** TLS is the same technology that puts the padlock in your browser. With TLS on Kafka listeners, every message travelling between clients and brokers is scrambled, so anyone intercepting the network traffic sees only gibberish.
- **SCRAM authentication:** SCRAM-SHA-512 is a secure password method. The password is never sent across the network in readable form; instead a cryptographic proof is exchanged. Only clients with valid credentials, managed by the Strimzi user operator, can connect.
- **KMS secret encryption:** Kubernetes stores configuration secrets (passwords, certificates). This project wraps them with a dedicated AWS KMS key so they are encrypted at rest. Even someone who reads the raw storage cannot use the secrets without access to the key, which is separately controlled and auto-rotated.
- **GitHub OIDC — no stored keys:** Normally CI pipelines store long-lived AWS keys, which are a prime target if leaked. OIDC instead lets GitHub prove its identity to AWS for each run and receive a short-lived token that expires quickly. There are no permanent AWS secrets sitting in GitHub at all.
- **Pod Security Standards:** The “restricted” Pod Security Standard forbids risky pod settings (like running as the root user or gaining extra system privileges). Combined with IRSA, this limits how much damage a compromised container could do.
- **tfsec & Checkov scanning:** These are automated tools that read your Terraform code and flag insecure settings (an open security group, an unencrypted volume, etc.) *before* the code is ever applied. In this project they run in the pipeline and can block a risky change from merging.

> ⚠️ **One thing to change before production:** the EKS public API endpoint is open to `0.0.0.0/0` in the example so CI can reach it. Lock it to your office or CI IP range by editing `public_access_cidrs` in the EKS module.

**References:** [EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/) · [Securing Kafka with Strimzi](https://strimzi.io/docs/operators/latest/deploying#assembly-securing-kafka-str)

-----

## 5. How Apache Kafka works

Kafka is a **distributed log**. Think of a notebook where you only ever add new lines at the bottom and never erase. Programs that send data are **producers**; programs that read it are **consumers**. Kafka keeps the notebook safe and lets many readers read at their own pace.

### 5.1 The core words, in plain terms

- **Topic** — A named channel for a kind of message — like a labeled mailbox, e.g. `demo-messages`.
- **Partition** — A topic is split into partitions so the work can be shared across machines. More partitions = more parallel readers.
- **Offset** — The line number in the notebook. A consumer remembers its offset so it can pick up where it left off.
- **Broker** — One Kafka server. A *cluster* is several brokers working together. This project runs 3.
- **Replica** — A backup copy of a partition on another broker. If one broker dies, a replica takes over.
- **Consumer group** — A team of consumers sharing the work of one topic. Kafka gives each partition to one member.

> ℹ️ **Partitions explained:** A partition is a slice of a topic. Splitting a topic into, say, 6 partitions lets 6 consumers read in parallel — 6× the speed. Order is guaranteed *within* a partition but not across partitions, so you choose a key (like a customer ID) to keep related messages together in one partition.

> ℹ️ **Consumer groups:** A consumer group is a team of readers sharing one topic. Kafka assigns each partition to exactly one member of the group, so the work is divided with no duplication. If a member dies, Kafka automatically gives its partitions to the others — this is called a *rebalance*.

### 5.2 The journey of one message

1. A **producer** sends a message to a topic. Kafka chooses a partition (by a key, or round-robin).
1. The **leader broker** for that partition writes the message and copies it to the replicas.
1. Once enough replicas confirm (`min.insync.replicas = 2` here), Kafka tells the producer “got it.”
1. A **consumer** reads from its last offset, processes the message, and records the new offset.

### 5.3 KRaft: no more ZooKeeper

Older Kafka needed a separate helper called ZooKeeper to keep track of the cluster. Modern Kafka (used here) uses **KRaft**, where Kafka manages itself. Fewer moving parts means less to break and less to secure.

> ℹ️ **KRaft mode:** KRaft (Kafka Raft) is how modern Kafka manages its own cluster information using a built-in consensus protocol, removing the old dependency on ZooKeeper. Fewer separate systems means simpler operations, faster recovery, and a smaller security surface.

### 5.4 Strimzi: Kafka the Kubernetes way

Running Kafka by hand on Kubernetes is fiddly. **Strimzi** is an *operator* — a program that lives in the cluster and manages Kafka for you. You describe the Kafka you want in a short YAML file, and Strimzi creates brokers, certificates, users, and storage, and handles upgrades.

> ℹ️ **What is a Kubernetes operator?** An operator is a program that runs inside Kubernetes and automates the care of a complex application — doing what a human expert would do. Strimzi is the operator for Kafka: it reads your simple “I want a Kafka cluster” request and handles brokers, TLS certificates, users, storage, and version upgrades for you.

**References:** [Apache Kafka docs](https://kafka.apache.org/documentation/) · [Strimzi docs](https://strimzi.io/docs/operators/latest/overview) · [KRaft](https://kafka.apache.org/documentation/#kraft)

-----

## 6. Fault tolerance & high availability

“Fault tolerance” means the system keeps working when a part fails. “High availability” (HA) means it is almost always up. Here is how this project achieves both, layer by layer.

- **Replication factor 3** — Every partition has 3 copies on 3 different brokers. Two brokers can fail and your data still exists.
- **min.insync.replicas = 2** — A write is only confirmed once 2 copies are safely stored. This prevents data loss if a single broker dies right after a write.
- **3 brokers across 3 zones** — Brokers run in separate AWS Availability Zones, so an entire data-center outage loses at most one broker.
- **Persistent storage** — Each broker stores data on a persistent volume that survives a pod restart, with `deleteClaim: false` so data is not wiped if the pool is removed.
- **Self-healing Kubernetes** — If a broker pod crashes, Kubernetes restarts it automatically. Strimzi re-attaches its storage and identity.
- **Node autoscaling range** — The node group can grow from 3 to 5 machines, giving room to reschedule work when a node is lost.

> ⚠️ **The key trade-off to understand:** with `replication=3` and `min.insync.replicas=2`, you can lose **one** broker and still accept writes. If you lose two at once, Kafka will pause writes to that partition rather than risk losing data — a deliberate safety choice. To tolerate two simultaneous failures while still writing, you would move to 5 brokers.

### Admin checklist for HA

- ✓ Watch `UnderReplicatedPartitions` — it should always be 0.
- ✓ Make sure brokers are actually in different zones (check node labels).
- ✓ Test failure on purpose: delete one broker pod and confirm the cluster recovers.
- ✓ Keep disk usage below ~70% so a failover has room to catch up.

-----

## 7. Monitoring: OpenTelemetry, Prometheus & Grafana

You cannot fix what you cannot see. This project watches the system in two complementary ways: metrics from **Kafka itself**, and metrics from the **applications** that send and receive messages.

### 7.1 The three tools and their jobs

- **OpenTelemetry** — A standard way for apps to emit *metrics* and *traces*. The producer/consumer push their numbers to an OTEL *Collector*.
- **Prometheus** — A database that *scrapes* (regularly pulls) metrics and stores them over time so you can query them.
- **Grafana** — The dashboard tool that turns Prometheus data into charts a human can read at a glance.

> ℹ️ **OpenTelemetry (OTEL):** OTEL is a vendor-neutral standard for collecting telemetry: metrics (numbers over time, like messages/sec), traces (the path of one request through the system), and logs. Because it is a standard, you can switch monitoring backends later without rewriting your apps.

### 7.2 How the data flows

```
producer ─┐
          ├─ OTLP ─▶ OTEL Collector ─(exposes /metrics)─┐
consumer ─┘                                             ├─▶ Prometheus ─▶ Grafana
kafka broker ─ JMX agent (port 9404) ───────────────────┘
```

The Kafka broker exposes its internal Java metrics through a small **JMX Prometheus agent** on port 9404. The apps send their metrics to the **OTEL Collector**, which re-exposes them in Prometheus format. Prometheus scrapes both, and Grafana draws the picture.

> ℹ️ **JMX and the exporter:** Kafka runs on Java, which exposes internal statistics through a mechanism called JMX. The JMX Prometheus agent runs inside the broker, reads those statistics, and republishes them on a web port (9404) in the format Prometheus understands. That is how broker-level metrics reach your dashboards.

### 7.3 What the dashboard shows

- Total messages produced and consumed.
- Produced vs. consumed rate per second (are consumers keeping up?).
- Kafka broker messages-in per topic, and bytes in/out.
- End-to-end latency (p95): how long from send to receive.

**References:** [OpenTelemetry docs](https://opentelemetry.io/docs/) · [Prometheus docs](https://prometheus.io/docs/introduction/overview/) · [Grafana docs](https://grafana.com/docs/)

-----

## 8. Example Prometheus (PromQL) queries

Paste these into the Prometheus expression box (`http://localhost:9090`) or a Grafana panel. A *query* asks the metrics database a question. `rate(...[1m])` means “per-second average over the last minute.”

**Message flow (from the apps):**

```promql
# Messages per second being produced
sum(rate(messages_produced_total[1m]))

# Messages per second being consumed
sum(rate(messages_consumed_total[1m]))

# Backlog: total produced minus total consumed
sum(messages_produced_total) - sum(messages_consumed_total)
```

**End-to-end latency (from the consumer):**

```promql
# 95th-percentile latency in milliseconds
histogram_quantile(0.95,
  sum(rate(message_latency_ms_bucket[5m])) by (le))

# Average latency
sum(rate(message_latency_ms_sum[5m]))
  / sum(rate(message_latency_ms_count[5m]))
```

**Kafka broker throughput (from JMX):**

```promql
# Messages arriving at the broker per topic
sum by (topic) (
  rate(kafka_server_brokertopicmetrics_messagesin_total[1m]))

# Bytes in / out across the whole cluster
sum(rate(kafka_server_brokertopicmetrics_bytesin_total[1m]))
sum(rate(kafka_server_brokertopicmetrics_bytesout_total[1m]))
```

**Health checks:**

```promql
# Under-replicated partitions — should always be 0
kafka_server_replicamanager_underreplicatedpartitions

# Which scrape targets are alive (1) or down (0)
up
```

> **Tip:** if a query returns nothing, the metric name may differ slightly. Type a prefix like `kafka_server_` in the Prometheus box and use its autocomplete to find the real name. Make the `rate()` window at least 4× the scrape interval (this stack scrapes every 5 seconds, so `[1m]` is safe).

-----

## 9. Simple use cases for an admin team

Everyday tasks, in the order you are likely to meet them.

### A. “Is the system healthy right now?”

Open Grafana, check that produced and consumed rates roughly match, and that under-replicated partitions is 0.

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# open http://localhost:3000
```

### B. “Are the Kafka brokers running?”

```bash
kubectl -n kafka get pods
kubectl -n kafka get kafka,kafkanodepool
```

### C. “Create a new topic for a new project”

With Strimzi you declare topics as YAML; the operator creates them. No manual broker commands.

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: orders
  namespace: kafka
  labels:
    strimzi.io/cluster: demo-kafka
spec:
  partitions: 6
  replicas: 3
```

### D. “A consumer is falling behind”

Check the backlog query in section 8. If it keeps growing, add more consumers to the group (up to the number of partitions) or add partitions to the topic.

### E. “Practice a failure safely”

Delete one broker pod and watch Kubernetes + Strimzi bring it back. Messages should keep flowing.

```bash
kubectl -n kafka delete pod demo-kafka-pool-0
kubectl -n kafka get pods -w   # watch it return
```

-----

## 10. Getting started, step by step

### Try it locally first (only Docker needed)

```bash
cd local
./kafka/setup.sh          # one-time: fetch the JMX agent
docker compose up --build # start Kafka, apps, Prometheus, Grafana
# Grafana:    http://localhost:3000  (admin / admin)
# Prometheus: http://localhost:9090
```

### Then deploy to AWS

```bash
cd terraform
export TF_VAR_grafana_admin_password="a-strong-password"
terraform init
terraform plan
terraform apply
# afterwards:
aws eks update-kubeconfig --region us-east-1 --name demo-kafka
```

Full instructions and the one-time AWS OIDC bootstrap are in the project README and `docs/AWS_OIDC_SETUP.md`.

-----

## 11. References & official docs

- [Apache Kafka](https://kafka.apache.org/documentation/) — Official Kafka documentation
- [Strimzi](https://strimzi.io/documentation/) — Kafka operator for Kubernetes
- [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/) — EKS user guide
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/) — Security, reliability, networking
- [Terraform](https://developer.hashicorp.com/terraform/docs) — Language and CLI reference
- [OpenTelemetry](https://opentelemetry.io/docs/) — Metrics, traces, and the Collector
- [Prometheus](https://prometheus.io/docs/) — PromQL and scraping
- [Grafana](https://grafana.com/docs/) — Dashboards and panels

-----

*Kafka on EKS — Technical Guide. Built for platform & admin teams. This document is informational; verify versions and security settings against the official docs before production use.*