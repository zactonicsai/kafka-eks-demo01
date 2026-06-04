variable "name" {
  description = "Cluster name prefix"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control plane version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC the cluster runs in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for worker nodes"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group"
  type        = string
  default     = "t3.large"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum worker nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum worker nodes"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
