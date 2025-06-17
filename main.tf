provider "aws" {
  region = var.aws_region
}

# S3 bucket for storing Streamlit app code and data
resource "aws_s3_bucket" "streamlit_app_bucket" {
  bucket = var.app_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "streamlit_app_bucket_ownership" {
  bucket = aws_s3_bucket.streamlit_app_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "streamlit_app_bucket_access" {
  bucket = aws_s3_bucket.streamlit_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.app_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.app_name}-lambda-s3-policy"
  description = "Allow Lambda to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.streamlit_app_bucket.arn,
          "${aws_s3_bucket.streamlit_app_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function for Streamlit app
resource "aws_lambda_function" "streamlit_app" {
  function_name = var.app_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 1024

  s3_bucket = aws_s3_bucket.streamlit_app_bucket.bucket
  s3_key    = "lambda_function.zip"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.streamlit_app_bucket.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_s3_policy_attachment
  ]
}

# API Gateway REST API
resource "aws_apigatewayv2_api" "streamlit_api" {
  name          = "${var.app_name}-api"
  protocol_type = "HTTP"
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "streamlit_stage" {
  api_id      = aws_apigatewayv2_api.streamlit_api.id
  name        = "$default"
  auto_deploy = true
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "streamlit_lambda_integration" {
  api_id             = aws_apigatewayv2_api.streamlit_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.streamlit_app.invoke_arn
  integration_method = "POST"
}

# API Gateway route
resource "aws_apigatewayv2_route" "streamlit_route" {
  api_id    = aws_apigatewayv2_api.streamlit_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.streamlit_lambda_integration.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.streamlit_app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.streamlit_api.execution_arn}/*/*"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "streamlit_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = "${aws_apigatewayv2_api.streamlit_api.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_id   = "apiGateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apiGateway"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}