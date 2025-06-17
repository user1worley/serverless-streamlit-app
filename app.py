import streamlit as st
import boto3
import os
import json
from mangum import Mangum
import folium
from streamlit_folium import folium_static
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderUnavailable

# Initialize the Streamlit app
def streamlit_app():
    st.title("Serverless Streamlit Application")
    
    st.write("Welcome to the serverless Streamlit app!")
    
    # City search and map display
    st.header("City Map Viewer")
    city_input = st.text_input("Enter a city name to view on map", "")
    
    if st.button("Show City Map"):
        if city_input:
            with st.spinner(f"Loading map for {city_input}..."):
                coordinates = get_city_coordinates(city_input)
                if coordinates:
                    display_city_map(city_input, coordinates)
                else:
                    st.error(f"Could not find coordinates for {city_input}. Please check the city name and try again.")
        else:
            st.warning("Please enter a city name.")
    
    # Example: Display data from S3
    st.header("S3 Data Viewer")
    if st.button("Load Data from S3"):
        data = load_data_from_s3()
        st.write(data)
    
    # Example: User input
    st.header("Text Processor")
    user_input = st.text_input("Enter some text")
    if st.button("Process"):
        result = process_data(user_input)
        st.write(result)

# Function to get city coordinates using geocoding
def get_city_coordinates(city_name):
    try:
        geolocator = Nominatim(user_agent="serverless-streamlit-app")
        location = geolocator.geocode(city_name)
        if location:
            return (location.latitude, location.longitude)
        return None
    except (GeocoderTimedOut, GeocoderUnavailable) as e:
        st.error(f"Geocoding error: {str(e)}")
        return None
    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
        return None

# Function to display city map
def display_city_map(city_name, coordinates):
    try:
        # Create a map centered at the city's coordinates
        m = folium.Map(location=coordinates, zoom_start=12)
        
        # Add a marker for the city
        folium.Marker(
            location=coordinates,
            popup=city_name,
            tooltip=city_name,
            icon=folium.Icon(color="red", icon="info-sign")
        ).add_to(m)
        
        # Display the map
        st.subheader(f"Map of {city_name}")
        folium_static(m)
        
        # Display the coordinates
        st.write(f"Latitude: {coordinates[0]}, Longitude: {coordinates[1]}")
    except Exception as e:
        st.error(f"Error displaying map: {str(e)}")

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