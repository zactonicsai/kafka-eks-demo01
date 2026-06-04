# ---------------------------------------------------------------------------
# Monitoring stack: kube-prometheus-stack bundles Prometheus + Grafana +
# Alertmanager. A PodMonitor scrapes the Strimzi brokers' JMX metrics.
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Let Prometheus discover PodMonitors/ServiceMonitors in ALL namespaces
  # so it finds the Kafka brokers in the kafka namespace.
  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Grafana admin password injected from a secret/var (never committed).
  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Persist Grafana dashboards across restarts.
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }
}

# PodMonitor: tells Prometheus to scrape the JMX-exporter port (9404) on brokers.
resource "kubernetes_manifest" "kafka_pod_monitor" {
  manifest = yamldecode(<<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      name: kafka-resources-metrics
      namespace: ${var.namespace}
      labels:
        app: strimzi
    spec:
      selector:
        matchLabels:
          strimzi.io/kind: Kafka
      namespaceSelector:
        any: true
      podMetricsEndpoints:
        - path: /metrics
          port: tcp-prometheus   # the named metrics port Strimzi exposes
  YAML
  )
  depends_on = [helm_release.kube_prometheus_stack]
}
