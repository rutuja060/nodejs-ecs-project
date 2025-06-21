variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}

variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}

variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {}
variable "ec2_sg_id" {}
variable "account_id" {}

variable "secret_name" {}
variable "region" {}
variable "instance_profile_name" {}


variable "ecr_image" {}        # full image name including tag
variable "ecr_repo_url" {}     # just the ECR registry URL
variable "docker_image_tag" {}     # just the ECR registry URL
