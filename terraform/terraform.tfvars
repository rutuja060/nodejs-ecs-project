aws_region = "ap-south-1"

vpc_cidr = "10.0.0.0/16"

project_name = "nodejs-app"


public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

availability_zones = [
  "ap-south-1a",
  "ap-south-1b"
]

db_name     = "nodejsdb"
db_user     = "nodejsuser"
db_password = "MySecurePass-622"
db_port = "5432"

region        = "ap-south-1"
secret_name   = "nodejs-app-secret"

# Compute configuration
ami_id          = "ami-0b09627181c8d5778"  
instance_type   = "t3.micro"
key_name        = "nodejs-demo"     
desired_capacity = 1
max_size        = 4
min_size        = 1

s3_bucket = "nodejs-app-scripts-bucket"
docker_image_tag = "latest" 