variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the Streamlit application"
  type        = string
  default     = "streamlit-app"
}

variable "app_bucket_name" {
  description = "Name of the S3 bucket for storing app code and data"
  type        = string
  default     = "streamlit-app-bucket"
}