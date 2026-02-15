"""
REST API to expose db queries to an HTTP endpoint
Receives and handles incoming requests from the frontend
"""
from datetime import datetime, timezone
from typing import List

from fastapi import FastAPI, Query
from pydantic import BaseModel

from src.models.user import (
    UserQuery, Location, UserPreferences, BudgetRange, StayTime,
)
from src.services.retrieval import search_meters as run_search_pipeline

app = FastAPI(title="CS-125 API")

class MeterResponse(BaseModel):
    """
    JSON shape returned from db query
    """
    spaceid: str
    address: str
    rate_per_hour: float
    time_limit_minutes: int
    occupancy: str
    latitude: float
    longitude: float
    distance_to_destination_meters: float
    walk_time_minutes: int
    estimated_total_cost: float
    rank: int
    color_code: str

class SearchResponse(BaseModel):
    """
    Wrapper response with metadata
    """
    spots: List[MeterResponse]
    total_candidates_evaluated: int
    query_timestamp: str

def get_color_code(rank: int) -> str:
    """
    Determine color code based on rank
    1-3: green (highly recommended)
    4-7: yellow (good)
    8+: orange (acceptable)
    """
    if rank <= 3:
        return "green"
    elif rank <= 7:
        return "yellow"
    else:
        return "orange"

@app.get("/meters/search", response_model=SearchResponse)
def search_meters(
    lat: float = Query(..., description="User's current latitude"),
    lon: float = Query(..., description="User's current longitude"),
    destination: str = Query(..., description="Target address string"),
    budget: str = Query("MEDIUM", description="LOW, MEDIUM, or HIGH"),
    stay: str = Query("SHORT", description="SHORT, MEDIUM, or LONG"),
    top_k: int = Query(10, description="Number of results"),
) -> SearchResponse:
    """
    API endpoint to run full retrieval and ranking pipeline
    
    Input: User context (current location, target location, preferences)
    Output: Returns JSON with ranked candidate meters and metadata
    """
    query_start_time = datetime.now(timezone.utc)
    
    query = UserQuery(
        current_location=Location(lat=lat, lon=lon),
        current_time=query_start_time,
        target_location_address=destination,
        preferences=UserPreferences(
            budget_range=BudgetRange[budget.upper()],
            stay_time=StayTime[stay.upper()],
        ),
    )

    # Search for raw meters from ladot client
    results = run_search_pipeline(query, top_k=top_k)

    meter_responses = [
        MeterResponse(
            spaceid=m.spaceid,
            address=m.address,
            rate_per_hour=m.rate_per_hour,
            time_limit_minutes=m.time_limit_minutes,
            occupancy=m.occupancy.value,
            latitude=m.latitude,
            longitude=m.longitude,
            distance_to_destination_meters=m.distance_to_destination_meters,
            walk_time_minutes=m.walk_time_minutes,
            estimated_total_cost=m.estimated_total_cost,
            rank=m.rank,
            color_code=get_color_code(m.rank),
        )
        for m in results
    ]
    
    return SearchResponse(
        spots=meter_responses,
        total_candidates_evaluated=len(results),
        query_timestamp=query_start_time.isoformat(),
    )