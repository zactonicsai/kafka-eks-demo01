variable "name" {
  description = "Prefix name for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (worker nodes + Kafka live here)"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (NAT gateways / load balancers only)"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default     = {}
}
