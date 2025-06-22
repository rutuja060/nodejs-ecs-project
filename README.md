# Node.js Todo App - AWS Infrastructure

A simple but production-ready Node.js todo application running on AWS. This project shows how to deploy a real application with proper infrastructure, monitoring, and CI/CD.



- **Node.js API** with PostgreSQL database
- **Docker containers** running on EC2
- **Auto-scaling** based on load
- **Load balancer** for high availability
- **Automated deployments** via GitHub Actions
- **Monitoring and alerts** with CloudWatch

## Quick Start

### Prerequisites
You'll need these installed:
- AWS CLI (configured with your credentials)
- Terraform
- Docker
- Node.js 18+
- Git

### Deploy Everything

1. **Clone and setup:**
```bash
git clone <your-repo>
cd nodejs-app
```

2. **Configure your AWS region and settings:**
```bash
cd terraform
# Edit terraform.tfvars with your settings
```

3. **Deploy the infrastructure:**
```bash
terraform init
terraform plan
terraform apply
```

4. **Deploy the app:**
```bash
# Push to main branch to trigger deployment
git push origin main
```

5. **Test it:**
```bash
# Get your load balancer URL
terraform output alb_dns_name

# Test the health endpoint
curl http://your-alb-url/health

# Create a todo
curl -X POST http://your-alb-url/todos \
  -H "Content-Type: application/json" \
  -d '{"task": "Deploy to production"}'
```

## How the Infrastructure Works

### VPC Layout
```
Internet → ALB (Public) → EC2 Instances (Private) → RDS (Private)
```

- **Public subnets**: Load balancer and NAT gateway
- **Private subnets**: EC2 instances and RDS database
- **Security groups**: Only allow necessary traffic

### What Gets Created
- VPC with public/private subnets across 2 AZs
- Application Load Balancer
- Auto Scaling Group (1-4 EC2 instances)
- RDS PostgreSQL database
- ECR repository for Docker images
- S3 bucket for deployment artifacts
- CloudWatch dashboards and alarms
- IAM roles and security groups

## CI/CD Pipeline

The pipeline runs automatically when you push to the `main` branch:

1. **Tests**: Runs unit tests with a test database
2. **Build**: Creates Docker image and pushes to ECR
3. **Deploy**: Uses CodeDeploy to update running instances
4. **Rollback**: Automatically rolls back if deployment fails

### Manual Deployment
```bash
git add .
git commit -m "Update app"
git push origin main
```

The pipeline takes about 5-10 minutes to complete.

## Monitoring and Logging

### What's Monitored
The application has comprehensive monitoring with:
- **Structured JSON logging** for easy parsing
- **CloudWatch dashboards** with real-time metrics
- **Automated alerts** via email/SNS
- **Request tracking** with unique IDs
- **Performance metrics** for all components

### View Logs
```bash
# Real-time application logs
aws logs tail /ec2/nodejs-app --follow

# Search for errors
aws logs tail /ec2/nodejs-app --filter-pattern ERROR

# Last hour of logs
aws logs tail /ec2/nodejs-app --since 1h

# Search for specific request IDs
aws logs tail /ec2/nodejs-app --filter-pattern "requestId"
```

### Log Format
All logs are in structured JSON format:
```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "type": "api_request",
  "message": "API request received",
  "method": "POST",
  "url": "/todos",
  "ip": "192.168.1.1",
  "userAgent": "curl/7.68.0",
  "requestId": "abc123def"
}
```

### CloudWatch Dashboard
Go to AWS Console → CloudWatch → Dashboards → `nodejs-app-dashboard`

**What you'll see:**
- **EC2 Metrics**: CPU, Network I/O, memory usage
- **Load Balancer**: Request counts, response times, HTTP status codes
- **Application Errors**: Real-time error logs and counts

### Alerts and Notifications
The system automatically alerts you when:
- **CPU usage** goes above 85% for 2 periods
- **Database memory** drops below 1GB
- **Database connections** exceed 80
- **Response times** are slow (>5 seconds)
- **HTTP 5XX errors** exceed 10 in 5 minutes

# Apply the changes
terraform apply
```

### CloudWatch Insights Queries
Use these queries in CloudWatch Insights for analysis:

**Error Rate Analysis:**
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)
```

**API Performance:**
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /api_response/
| parse @message /"duration": "(\d+)ms"/
| stats avg(@duration) by bin(1m)
```

**Database Errors:**
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /database_error/
| stats count() by bin(5m)
```

### Request Tracking
Every request gets a unique `requestId` that:
- Is automatically generated if not provided
- Added to response headers as `X-Request-ID`
- Included in all related log entries
- Helps trace requests across the system

### Monitoring Commands
```bash
# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names-prefix nodejs-app

# Check alarm history
aws cloudwatch describe-alarm-history --alarm-name nodejs-app-high-cpu

# Monitor Auto Scaling
aws autoscaling describe-scaling-activities --auto-scaling-group-name app-asg

# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
```

## Local Development

### Run Locally
```bash
npm install
npm start
```

### Run with Docker
```bash
docker-compose up
```

### Run Tests
```bash
npm test
```

### Environment Variables
Create a `.env` file:
```env
DB_USER=nodejsuser
DB_PASSWORD=your_password
DB_NAME=nodejsdb
DB_HOST=localhost
DB_PORT=5432
PORT=3000
```

## API Endpoints

| Method | Endpoint | What it does |
|--------|----------|--------------|
| GET | `/` | Welcome message |
| GET | `/health` | Health check |
| GET | `/todos` | Get all todos |
| POST | `/todos` | Create new todo |
| PUT | `/todos/:id` | Update todo |
| DELETE | `/todos/:id` | Delete todo |

## Troubleshooting

### Common Issues

**Application won't start:**
```bash
# Check container logs
sudo docker logs -f nodejs-app

# Check if port 3000 is in use
sudo netstat -tlnp | grep 3000
```

**Database connection fails:**
```bash
# Test connectivity
telnet your-rds-endpoint 5432

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

**Load balancer health checks failing:**
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Check if app responds locally
curl http://localhost:3000/health
```

**Deployment stuck:**
```bash
# Check CodeDeploy status
aws deploy get-deployment --deployment-id d-xxxxx

# Check GitHub Actions
# Go to your repo → Actions tab
```


## Design Decisions

### Why These Choices?

**Terraform over CloudFormation:**
- Better state management
- More readable syntax
- Multi-cloud support (if needed later)

**Private subnets for EC2:**
- Better security
- No direct internet access
- Forces traffic through load balancer

**Auto Scaling Group:**
- Handles traffic spikes automatically
- High availability

**CodeDeploy over direct deployment:**
- Rolling update deployment capability
- Automatic rollback on failure
- Better deployment tracking

**Structured JSON logging:**
- Easier to parse and analyze
- Better for monitoring tools
- Consistent log format

## Challenges I Faced

### Database Connection Issues
The RDS security group wasn't allowing connections from EC2. Fixed by:
- Adding proper ingress rules
- Configuring SSL for database connections
- Testing connectivity after infrastructure changes

### Express.js Version Problems
Express 5.x had breaking changes that caused the app to crash. Solution:
- Downgraded to Express 4.18.2
- Updated package-lock.json
- Tested thoroughly before deployment

### Load Balancer Health Checks
Instances weren't attaching to the load balancer because:
- Application was crashing on startup
- Health check endpoint wasn't responding
- Fixed by ensuring app starts properly

### Package Lock File Issues
CI/CD was failing because package-lock.json was out of sync. Fixed by:
- Running `npm install` after dependency changes
- Committing the updated lock file
- Ensuring consistency between package.json and package-lock.json


## Security Considerations

### What's Secured
- EC2 instances in private subnets
- Database not publicly accessible
- Secrets stored in AWS Secrets Manager
- SSL/TLS for database connections
- IAM roles with minimal permissions
