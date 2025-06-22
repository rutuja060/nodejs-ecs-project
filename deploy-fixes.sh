#!/bin/bash

echo "🚀 Deploying database connection fixes..."

# Build and push new Docker image
echo "📦 Building and pushing Docker image..."
docker build -t nodejs-app:latest .
docker tag nodejs-app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com/nodejs-ecs-project:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com/nodejs-ecs-project:latest

echo "✅ Docker image pushed successfully"

# Create deployment package
echo "📋 Creating deployment package..."
mkdir -p deployment
cp -r scripts deployment/
cp appspec.yml deployment/
echo "latest" > deployment/image-tag.txt
tar -czf deployment-package.tar.gz -C deployment .

# Upload to S3
echo "☁️ Uploading to S3..."
aws s3 cp deployment-package.tar.gz s3://$(aws s3 ls | grep nodejs | awk '{print $3}')/deployments/deployment-package.tar.gz --sse AES256

# Create CodeDeploy deployment
echo "🚀 Creating CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy create-deployment \
  --application-name nodejs-app \
  --deployment-group-name nodejs-app-deployment-group \
  --s3-location bucket=$(aws s3 ls | grep nodejs | awk '{print $3}'),key=deployments/deployment-package.tar.gz,bundleType=tar \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --description "Deploy database connection fixes" \
  --query 'deploymentId' --output text)

echo "📊 Deployment ID: $DEPLOYMENT_ID"
echo "⏳ Waiting for deployment to complete..."

aws deploy wait deployment-successful --deployment-id $DEPLOYMENT_ID

if [ $? -eq 0 ]; then
  echo "✅ Deployment completed successfully!"
  echo "🌐 Your application should now be working at:"
  echo "   http://app-alb-656664547.ap-south-1.elb.amazonaws.com"
else
  echo "❌ Deployment failed!"
  aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --query 'deploymentInfo.errorInformation'
fi

# Cleanup
rm -rf deployment deployment-package.tar.gz 