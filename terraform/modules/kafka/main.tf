# ---------------------------------------------------------------------------
# Kafka on EKS using the Strimzi Operator (production-grade Kafka on K8s).
# Why Strimzi: it manages brokers, TLS certs, users, and rolling upgrades
# declaratively. We enable:
#   * TLS encryption on all listeners
#   * SCRAM-SHA-512 authentication
#   * Prometheus JMX metrics exporter on every broker
#
# NOTE: the Strimzi custom resources are built here as native Terraform
# objects (not rendered from a templated YAML file). This avoids two traps:
#   1. templatefile() interprets every $ {..} in the file (even in comments),
#      which caused parse errors.
#   2. yamldecode() only accepts a SINGLE YAML document, so a file with a
#      "---" separator (Kafka + KafkaNodePool) cannot be decoded at once.
# Each custom resource is therefore its own kubernetes_manifest resource.
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = var.namespace
    labels = {
      # Restrict pod privileges per Pod Security Standards (best practice).
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

# Install the Strimzi operator that watches for Kafka custom resources.
resource "helm_release" "strimzi" {
  name       = "strimzi-operator"
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  version    = var.strimzi_version
  namespace  = kubernetes_namespace.kafka.metadata[0].name

  set {
    name  = "watchNamespaces"
    value = "{${var.namespace}}"
  }
}

# ConfigMap consumed by the JMX Prometheus exporter inside each broker.
# It translates Kafka's JMX MBeans into Prometheus metrics.
resource "kubernetes_manifest" "kafka_metrics_config" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "kafka-metrics"
      namespace = var.namespace
      labels    = { app = "strimzi" }
    }
    data = {
      "kafka-metrics-config.yml" = <<-METRICS
        # Turn key broker JMX beans into Prometheus time series.
        lowercaseOutputName: true
        rules:
          # Per-topic messages-in / bytes-in/out (core message-tracking metrics).
          - pattern: kafka.server<type=(.+), name=(.+)PerSec, topic=(.+)><>Count
            name: kafka_server_$1_$2_total
            type: COUNTER
            labels:
              topic: "$3"
          # Broker-wide throughput (no topic label).
          - pattern: kafka.server<type=(.+), name=(.+)PerSec><>Count
            name: kafka_server_$1_$2_total
            type: COUNTER
          # Under-replicated partitions and similar health signals.
          - pattern: kafka.server<type=ReplicaManager, name=(.+)><>Value
            name: kafka_server_replicamanager_$1
            type: GAUGE
          # Request / network metrics.
          - pattern: kafka.network<type=(.+), name=(.+)><>Count
            name: kafka_network_$1_$2_total
            type: COUNTER
      METRICS
    }
  }
  depends_on = [helm_release.strimzi]
}

# The Kafka cluster: KRaft mode, TLS + SCRAM-SHA-512, JMX Prometheus metrics.
resource "kubernetes_manifest" "kafka_cluster" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"
    metadata = {
      name      = var.name
      namespace = var.namespace
      annotations = {
        "strimzi.io/node-pools" = "enabled" # use KafkaNodePool (KRaft, no ZooKeeper)
        "strimzi.io/kraft"      = "enabled"
      }
    }
    spec = {
      kafka = {
        version = var.kafka_version
        # Every listener encrypts in transit (TLS) + authenticates (SCRAM).
        listeners = [{
          name = "tls"
          port = 9093
          type = "internal"
          tls  = true
          authentication = {
            type = "scram-sha-512"
          }
        }]
        config = {
          "offsets.topic.replication.factor"         = 3
          "transaction.state.log.replication.factor" = 3
          "transaction.state.log.min.isr"            = 2
          "default.replication.factor"               = 3
          "min.insync.replicas"                      = 2 # ack only when 2 replicas have the write
        }
        # Expose JMX metrics in Prometheus format from the ConfigMap above.
        metricsConfig = {
          type = "jmxPrometheusExporter"
          valueFrom = {
            configMapKeyRef = {
              name = "kafka-metrics"
              key  = "kafka-metrics-config.yml"
            }
          }
        }
      }
      entityOperator = {
        topicOperator = {} # declare topics as KafkaTopic CRs
        userOperator  = {} # declare users/passwords as KafkaUser CRs
      }
    }
  }
  depends_on = [kubernetes_manifest.kafka_metrics_config]
}

# KafkaNodePool: the actual broker pods (KRaft combined controller+broker role).
resource "kubernetes_manifest" "kafka_node_pool" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaNodePool"
    metadata = {
      name      = "${var.name}-pool"
      namespace = var.namespace
      labels = {
        "strimzi.io/cluster" = var.name
      }
    }
    spec = {
      replicas = var.kafka_replicas
      roles    = ["controller", "broker"] # combined mode
      storage = {
        type        = "persistent-claim"
        size        = "20Gi"
        deleteClaim = false # keep data if the pool is deleted (safety)
      }
    }
  }
  depends_on = [kubernetes_manifest.kafka_cluster]
}
