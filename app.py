import streamlit as st
import boto3
import os
import json
from mangum import Mangum

# Initialize the Streamlit app
def streamlit_app():
    st.title("Serverless Streamlit Application")
    
    st.write("Welcome to the serverless Streamlit app!")
    
    # Example: Display data from S3
    if st.button("Load Data from S3"):
        data = load_data_from_s3()
        st.write(data)
    
    # Example: User input
    user_input = st.text_input("Enter some text")
    if st.button("Process"):
        result = process_data(user_input)
        st.write(result)

# Function to load data from S3
def load_data_from_s3():
    try:
        s3_bucket = os.environ.get('S3_BUCKET')
        s3_client = boto3.client('s3')
        response = s3_client.get_object(Bucket=s3_bucket, Key='data/sample.json')
        data = json.loads(response['Body'].read().decode('utf-8'))
        return data
    except Exception as e:
        return {"error": str(e)}

# Function to process user input
def process_data(input_text):
    # Example processing logic
    return {
        "input": input_text,
        "processed": input_text.upper(),
        "length": len(input_text)
    }

# Lambda handler
def handler(event, context):
    # Initialize Mangum with the Streamlit app
    handler = Mangum(streamlit_app)
    return handler(event, context)

# For local development
if __name__ == "__main__":
    streamlit_app()