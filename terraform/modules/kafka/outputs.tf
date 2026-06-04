output "namespace" {
  description = "Namespace Kafka was deployed into"
  value       = var.namespace
}

output "bootstrap_service" {
  description = "In-cluster bootstrap address for the TLS listener"
  value       = "${var.name}-kafka-bootstrap.${var.namespace}.svc:9093"
}
