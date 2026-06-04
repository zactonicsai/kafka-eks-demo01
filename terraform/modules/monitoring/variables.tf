variable "namespace" {
  description = "Namespace for the monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "65.1.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (set via TF var / secret, never hardcode)"
  type        = string
  sensitive   = true
}
