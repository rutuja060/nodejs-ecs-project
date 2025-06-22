# Monitoring and Logging Setup

This document describes the monitoring and logging infrastructure for the Node.js application.

## 🌐 Application Access
- **Load Balancer**: HTTP only (port 80)
- **Application**: Runs on port 3000
- **No SSL/HTTPS**: Currently using HTTP only (no domain name required)

## 📊 CloudWatch Monitoring

### Dashboards
- **Main Dashboard**: `/aws/cloudwatch/dashboards/nodejs-app-dashboard`
  - EC2 metrics (CPU, Network I/O)
  - ALB metrics (Request count, Response time, HTTP status codes)
  - RDS metrics (CPU, Memory, Connections)
  - Application error logs

### CloudWatch Alarms

#### Auto Scaling Alarms
- **High CPU**: Triggers when CPU > 80% for 2 periods (5 minutes each)
- **Low CPU**: Triggers when CPU < 20% for 2 periods (5 minutes each)

#### Application Alarms
- **High Response Time**: Triggers when ALB target response time > 5 seconds
- **HTTP 5XX Errors**: Triggers when 5XX error count > 10 in 5 minutes
- **RDS High Memory**: Triggers when RDS freeable memory < 1GB
- **RDS High Connections**: Triggers when database connections > 80

### SNS Notifications
- Email notifications sent to configured email address
- All alarms are configured to send notifications via SNS

## 📝 Structured Logging

### Log Format
All application logs are in JSON format for easy parsing and analysis:

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

### Log Levels
- **INFO**: Normal application flow
- **WARN**: Non-critical issues (validation errors, not found)
- **ERROR**: Critical errors (database failures, exceptions)
- **DEBUG**: Detailed debugging information

### Log Types
- **api_request**: Incoming API requests
- **api_response**: Successful API responses
- **api_error**: API errors and failures
- **database_connect**: Database connection events
- **database_error**: Database errors
- **startup**: Application startup events
- **shutdown**: Application shutdown events

### Request Tracking
Each request gets a unique `requestId` that is:
- Generated automatically if not provided
- Added to response headers as `X-Request-ID`
- Included in all related log entries

## 🔍 CloudWatch Logs

### Log Groups
- **Application Logs**: `/ec2/nodejs-app`
  - Retention: 14 days
  - Streams: One per EC2 instance

### Log Queries
Example CloudWatch Insights queries:

#### Error Rate
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)
```

#### API Performance
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /api_response/
| parse @message /"duration": "(\d+)ms"/
| stats avg(@duration) by bin(1m)
```

#### Database Errors
```
SOURCE '/ec2/nodejs-app'
| fields @timestamp, @message
| filter @message like /database_error/
| stats count() by bin(5m)
```

## 🚨 Alerting

### Email Alerts
Configure your email address in the Terraform variables:
```hcl
variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = "your-email@example.com"
}
```

### Slack Integration (Optional)
To add Slack notifications, create an SNS topic subscription:
```bash
aws sns subscribe \
  --topic-arn arn:aws:s3:region:account:nodejs-app-alerts \
  --protocol https \
  --notification-endpoint https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

## 📈 Metrics Collection

### Application Metrics
- Request count and response times
- Error rates by endpoint
- Database connection pool status
- Memory and CPU usage

### Infrastructure Metrics
- EC2 instance health and performance
- ALB request distribution
- RDS database performance
- Auto Scaling Group activity

## 🔧 Troubleshooting

### View Application Logs
```bash
# View logs for a specific instance
aws logs tail /ec2/nodejs-app --follow

# View logs for the last hour
aws logs tail /ec2/nodejs-app --since 1h

# Search for errors
aws logs tail /ec2/nodejs-app --filter-pattern ERROR
```

### Check CloudWatch Alarms
```bash
# List all alarms
aws cloudwatch describe-alarms --alarm-names-prefix nodejs-app

# Check alarm history
aws cloudwatch describe-alarm-history --alarm-name nodejs-app-high-cpu
```

### Monitor Auto Scaling
```bash
# Check ASG activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name app-asg

# View scaling policies
aws autoscaling describe-policies --auto-scaling-group-name app-asg
```

## 🛠️ Local Development

### Test Logging Locally
```bash
# Run with structured logging
NODE_ENV=development npm start

# Test database connection
node test-db-connection.js
```

### View Local Logs
```bash
# Filter JSON logs
npm start | jq '.'

# Filter by log level
npm start | jq 'select(.level == "ERROR")'
```

## 📋 Best Practices

1. **Always use structured logging** - No console.log() statements
2. **Include request IDs** - For request tracing
3. **Log at appropriate levels** - INFO, WARN, ERROR, DEBUG
4. **Monitor error rates** - Set up alerts for high error rates
5. **Track performance** - Monitor response times and throughput
6. **Regular log analysis** - Review logs for patterns and issues
7. **Retention policies** - Configure appropriate log retention
8. **Security** - Never log sensitive data (passwords, tokens)

## 🔒 Security Notes

- **HTTP Only**: Currently using HTTP without SSL certificates
- **Internal Communication**: EC2 to RDS communication is secure within VPC
- **Security Groups**: Properly configured to restrict access
- **Secrets Management**: Database credentials stored in AWS Secrets Manager
- **Future Enhancement**: Can add HTTPS when domain name is available 