from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel
import os
import requests

from ..models import RawLatLng, RawMeterInventory, RawMeterOccupancy

# Create a base class to pass in as a JSON body to the query
class MeterSearchRequest(BaseModel):
    lat: float # destination latitude
    lon: float # destination longitude
    radius_m: float = 1609.34  # 1 mile in meters

load_dotenv()

# Create instance 
app = FastAPI()

# SODA v3 API requires authentication
# This increases rate limits
headers={}
headers["X-App-Token"] = os.getenv("LADOT_APP_TOKEN")

"""
Get available meters in the user's destination location
- Input: parsed coordinates 
- Output: list of available meters
"""
@app.post("/ladot-meters")
def get_meters_in_area(request: MeterSearchRequest) -> list[RawMeterInventory]:
    url = "https://data.lacity.org/resource/s49e-q6j2.json"

    # Use the API's built in within_circle() function
    location_boundary = (
        f"within_circle(latlng, {request.lat}, {request.lon}, {request.radius_m})"
    )

    params = {
        "$where": location_boundary,
        "$limit": 200
    }

    r = requests.get(url, params=params, headers=headers)
    
    # Parse raw JSON into typed dataclass instances
    return [
        RawMeterInventory(
            spaceid=item["spaceid"],
            blockface=item["blockface"],
            metertype=item["metertype"],
            ratetype=item["ratetype"],
            raterange=item["raterange"],
            timelimit=item["timelimit"],
            latlng=RawLatLng(
                latitude=item["latlng"]["latitude"],
                longitude=item["latlng"]["longitude"]
            )
        )
        for item in r.json()
    ]


"""
Return the most recent occupancy status of each parking meter
- Input: spaceIds of meters selected in region
- Output: list of occupancy for meters
"""
@app.post("/ladot-occupancy")
def get_occupancy(spaceids: list[str]) -> dict[str, RawMeterOccupancy]:
    url = "https://data.lacity.org/resource/e7h6-4a3e.json"

    if not spaceids: 
        return {}

    # Create a list of spaceids to check
    spaceid_list = ",".join(f"'{sid}'" for sid in spaceids)

    params = {
        "$where": f"spaceid in ({spaceid_list})",
        "$order": "eventtime DESC",
        "$limit": 1000
    }

    r = requests.get(url, params=params, headers=headers)
    r.raise_for_status()

    # Only keep most recent record per spaceid
    latest: dict[str, RawMeterOccupancy] = {}
    for record in r.json():
        sid = record["spaceid"]
        
        # Add the first occurrence in the descending list 
        if sid not in latest:
            latest[sid] = RawMeterOccupancy(
                spaceid=sid,
                eventtime=record.get("eventtime", ""),
                occupancystate=record.get("occupancystate", "UNKNOWN")
            )
    
    return latest


"""
Get all candidate meters open for the current time
- Input: 
- Output: space_id of top K results
"""
# @app.post("/search")
# def search_meters(request: searchRequest):
