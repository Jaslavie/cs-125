from dotenv import load_dotenv
from fastapi import FastAPI
import os
import uvicorn
import requests
from src.models import Location, Meter

load_dotenv()

# Create instance 
app = FastAPI()

# SODA v3 API requires authentication
# This increases rate limits
headers={}
headers["X-App-Token"] = os.getenv("LADOT_APP_TOKEN")

"""
Get available meters in the user's location radius
- Input: parsed coordinates of a user's location
- Output: list of available meters
"""
@app.post("/ladot-meters")
def get_meters_in_area(userLocation: Location):
    url = "https://data.lacity.org/resource/s49e-q6j2.json"
    
    radius = 100 # in meters

    # Use the API's built in within_circle() function
    location_boundary = (
        f"within_circle(latlng, {userLocation.lat}, {userLocation.lon}, {radius})"
    )

    params = {
        "$where": location_boundary,
        "$limit": 200
    }

    r = requests.get(url, params=params)
    return r.json()


"""
Get raw dataset of occupancy of each meter
- Input: Meter object queried by space_id
- Output: list of occupancy for meters
"""
# @app.post("/ladot-occupancy")
# def get_occupancy(meters: Meter) -> MeterOccupancies:

"""
Get all candidate meters open for the current time
- Input: 
- Output: space_id of top K results
"""
# @app.post("/search")
# def search_meters(request: searchRequest)