#!/bin/bash

# Exit on error
set -e

# Variables
APP_NAME="streamlit-app"
S3_BUCKET=$(terraform output -raw s3_bucket_name)

echo "Packaging Lambda function..."
pip install -r requirements.txt -t ./package
cp app.py ./package/
cd package
zip -r ../lambda_function.zip .
cd ..

echo "Uploading Lambda function to S3..."
aws s3 cp lambda_function.zip s3://$S3_BUCKET/lambda_function.zip

echo "Creating sample data file..."
echo '{"sample": "data", "values": [1, 2, 3, 4, 5]}' > sample.json
aws s3 cp sample.json s3://$S3_BUCKET/data/sample.json

echo "Updating Lambda function..."
aws lambda update-function-code --function-name $APP_NAME --s3-bucket $S3_BUCKET --s3-key lambda_function.zip

echo "Deployment complete!"
echo "API Gateway URL: $(terraform output -raw api_gateway_url)"
echo "CloudFront Domain: $(terraform output -raw cloudfront_domain)"