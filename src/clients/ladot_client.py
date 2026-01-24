import dotenv
from fastapi import FastAPI
import uvicorn

dotenv.load()

# Create instance 
app = FastAPI()

# SODA v3 API requires authentication
# This increases rate limits
headers={}
headers["X-App-Token"] = LADOT_APP_TOKEN

INVENTORY_URL = "https://data.lacity.org/resource/s49e-q6j2.json"
OCCUPANCY_URL = "https://data.lacity.org/resource/e7h6-4a3e.json"

"""
Get available meters in the user's location radius
- Input: userQuery object includes user's location
- Output: list of available meters
"""
@app.post("/ladot-meters")
def get_meters_in_area(query: userQuery) -> Meter:

"""
Get raw dataset of occupancy of each meter
- Input: Meter object queried by space_id
- Output: list of occupancy for meters
"""
@app.post("/ladot-occupancy")
def get_occupancy(meters: Meter) -> MeterOccupancies:

"""
Get all candidate meters open for the current time
- Input: 
- Output: space_id of top K results
"""
@app.post("/search")
def search_meters(request: searchRequest)