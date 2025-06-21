variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "db_port" {
  default = 5432
}
variable "private_subnets" {}
variable "rds_sg_id" {}
