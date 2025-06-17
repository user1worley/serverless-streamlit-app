output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = aws_apigatewayv2_stage.streamlit_stage.invoke_url
}

output "cloudfront_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.streamlit_distribution.domain_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for app code and data"
  value       = aws_s3_bucket.streamlit_app_bucket.bucket
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.streamlit_app.function_name
}