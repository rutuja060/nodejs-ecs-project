provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "rds" {
  source          = "./modules/rds"
  db_name         = var.db_name
  db_user         = var.db_user
  db_password     = var.db_password
  private_subnets = module.vpc.private_subnets
  rds_sg_id       = module.vpc.rds_sg_id
}

module "secrets" {
  source       = "./modules/secrets"
  secret_name  = var.secret_name
  db_user      = var.db_user
  db_password  = var.db_password
  db_host      = module.rds.db_endpoint
  db_name      = var.db_name
  db_port      = var.db_port
}

module "s3" {
  source       = "./modules/s3"
  bucket_name  = var.s3_bucket
  environment  = "dev"
}

module "iam" {
  source      = "./modules/iam"
  region      = var.region
  secret_name = var.secret_name
  s3_bucket   = module.s3.bucket_name
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "nodejs-ecs-project"
  environment     = "dev"
}

module "compute" {
  source = "./modules/compute"
  
  # VPC and networking
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  alb_sg_id          = module.vpc.alb_sg_id
  ec2_sg_id          = module.vpc.ec2_sg_id
  account_id         = data.aws_caller_identity.current.account_id
  
  # EC2 configuration
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  
  # IAM and secrets
  instance_profile_name = module.iam.instance_profile_name
  secret_name           = var.secret_name
  region                = var.region
  
  # ECR configuration
  ecr_image        = "${module.ecr.repository_url}:${var.docker_image_tag}"
  ecr_repo_name    = module.ecr.repository_name
  docker_image_tag = var.docker_image_tag
  
  # CodeDeploy configuration
  codedeploy_service_role_arn = module.iam.codedeploy_service_role_arn
}
