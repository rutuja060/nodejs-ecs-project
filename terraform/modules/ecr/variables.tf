variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "environment" {
  description = "Environment label for tagging (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
