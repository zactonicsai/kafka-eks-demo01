variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Global name prefix for all resources"
  type        = string
  default     = "demo-kafka"
}

variable "grafana_admin_password" {
  description = "Grafana admin password — pass via TF_VAR_grafana_admin_password or CI secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "kafka-eks-demo"
    ManagedBy = "terraform"
  }
}
