# Serverless Streamlit Application

This project deploys a serverless Streamlit application using AWS Lambda, API Gateway, S3, and CloudFront.

## Architecture

The application follows a serverless architecture:
- **AWS Lambda**: Hosts the Streamlit application code
- **API Gateway**: Provides HTTP endpoints to access the application
- **S3**: Stores application code, dependencies, and data
- **CloudFront**: Delivers content with low latency

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Python 3.9+

## Deployment Instructions

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Apply the Terraform configuration:
   ```
   terraform apply
   ```

3. Deploy the application code:
   ```
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. Access the application using the CloudFront URL provided in the output.

## Customization

- Update `variables.tf` to customize the application name, region, and bucket name
- Modify `app.py` to implement your Streamlit application logic
- Update `requirements.txt` to add any additional Python dependencies

## Cleanup

To remove all resources:
```
terraform destroy
```