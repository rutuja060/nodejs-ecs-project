output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "codedeploy_service_role_arn" {
  value = aws_iam_role.codedeploy_service_role.arn
}
