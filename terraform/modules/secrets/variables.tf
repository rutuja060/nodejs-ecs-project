variable "secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  type        = string
}

variable "db_user" {}
variable "db_password" {}
variable "db_host" {}
variable "db_name" {}
variable "db_port" {}
