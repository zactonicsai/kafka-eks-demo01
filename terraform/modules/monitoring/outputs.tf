output "namespace" {
  description = "Monitoring namespace"
  value       = var.namespace
}

output "grafana_service" {
  description = "In-cluster Grafana service (port-forward to reach the UI)"
  value       = "kube-prometheus-stack-grafana.${var.namespace}.svc:80"
}
