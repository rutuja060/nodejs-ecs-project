variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for metrics"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/ec2/nodejs-app"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
} 