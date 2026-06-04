variable "name" {
  description = "Name prefix"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Kafka"
  type        = string
  default     = "kafka"
}

variable "strimzi_version" {
  description = "Strimzi Kafka Operator Helm chart version"
  type        = string
  default     = "0.51.0"
}

variable "kafka_replicas" {
  description = "Number of Kafka broker replicas"
  type        = number
  default     = 3
}

variable "kafka_version" {
  description = "Kafka version deployed by Strimzi (must be supported by the operator version)"
  type        = string
  default     = "4.2.0"
}
