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
  default     = "0.45.0"
}

variable "kafka_replicas" {
  description = "Number of Kafka broker replicas"
  type        = number
  default     = 3
}

variable "kafka_version" {
  description = "Kafka version deployed by Strimzi"
  type        = string
  default     = "3.8.0"
}
