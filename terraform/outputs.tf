output "cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig"
  value       = module.eks.cluster_name
}

output "kafka_bootstrap" {
  description = "In-cluster Kafka bootstrap address"
  value       = module.kafka.bootstrap_service
}

output "grafana_service" {
  description = "In-cluster Grafana service"
  value       = module.monitoring.grafana_service
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
