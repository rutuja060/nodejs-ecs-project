output "bucket_name" {
  value = aws_s3_bucket.codedeploy_artifacts.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.codedeploy_artifacts.arn
} 