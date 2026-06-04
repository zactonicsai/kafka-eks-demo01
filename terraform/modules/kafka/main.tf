# ---------------------------------------------------------------------------
# Kafka on EKS using the Strimzi Operator (production-grade Kafka on K8s).
# Why Strimzi: it manages brokers, TLS certs, users, and rolling upgrades
# declaratively. We enable:
#   * TLS encryption on all listeners
#   * SCRAM-SHA-512 authentication
#   * Prometheus JMX metrics exporter on every broker
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

# The Kafka cluster definition is applied as a raw manifest (kubectl) so we can
# express the full Strimzi CRD with metrics + security. Rendered from template.
resource "kubernetes_manifest" "kafka_metrics_config" {
  manifest = yamldecode(templatefile("${path.module}/manifests/kafka-metrics-configmap.yaml", {
    namespace = var.namespace
  }))
  depends_on = [helm_release.strimzi]
}

resource "kubernetes_manifest" "kafka_cluster" {
  manifest = yamldecode(templatefile("${path.module}/manifests/kafka-cluster.yaml", {
    name          = var.name
    namespace     = var.namespace
    replicas      = var.kafka_replicas
    kafka_version = var.kafka_version
  }))
  depends_on = [kubernetes_manifest.kafka_metrics_config]
}
