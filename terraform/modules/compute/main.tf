resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region           = var.region
    secret_name      = var.secret_name
    ecr_repo_name    = var.ecr_repo_name
    account_id       = var.account_id
    docker_image_tag = var.docker_image_tag
  }))

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_sg_id]
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app-instance"
    }
  }
}

# Automatically set the latest version as default
resource "null_resource" "set_default_version" {
  triggers = {
    launch_template_id = aws_launch_template.app.id
    latest_version     = aws_launch_template.app.latest_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 modify-launch-template \
        --launch-template-id ${aws_launch_template.app.id} \
        --default-version ${aws_launch_template.app.latest_version}
    EOT
  }

  depends_on = [aws_launch_template.app]
}

resource "aws_autoscaling_group" "app" {
  name                      = "app-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  vpc_zone_identifier       = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Default"
  }

  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "CodeDeploy"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_codedeploy_app" "app" {
  compute_platform = "Server"
  name             = "nodejs-app"
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "nodejs-app-deployment-group"
  service_role_arn       = var.codedeploy_service_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "CodeDeploy"
      type  = "KEY_AND_VALUE"
      value = "true"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.app_tg.name
    }
  }
}
