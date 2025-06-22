output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.app_alb.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.app.deployment_group_name
}
