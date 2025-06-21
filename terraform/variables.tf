variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# Database variables
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

# Compute variables
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity for Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size for Auto Scaling Group"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum size for Auto Scaling Group"
  type        = number
  default     = 1
}

# Secrets variables
variable "secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "region" {
  description = "AWS region (alias for aws_region)"
  type        = string
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy. Defaults to 'latest' for local runs."
  type        = string
  default     = "latest"
}

