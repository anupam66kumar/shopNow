variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-southeast-2"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "project4-shopnow-eks"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}
