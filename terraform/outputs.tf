output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "codedeploy_app_name" {
  value = module.compute.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  value = module.compute.codedeploy_deployment_group_name
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}
