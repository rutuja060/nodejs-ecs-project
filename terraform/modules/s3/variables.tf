variable "bucket_name" {
  description = "Name of the S3 bucket for CodeDeploy artifacts"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
} 