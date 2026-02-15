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
    distance_to_destination_meters: float
    walk_time_minutes: int
    estimated_total_cost: float
    rank: int

@app.get("/meters/search", response_model=list[MeterResponse])
def search_meters(
    lat: float = Query(..., description="User's current latitude"),
    lon: float = Query(..., description="User's current longitude"),
    destination: str = Query(..., description="Target address string"),
    budget: str = Query("MEDIUM", description="LOW, MEDIUM, or HIGH"),
    stay: str = Query("SHORT", description="SHORT, MEDIUM, or LONG"),
    top_k: int = Query(10, description="Number of results"),
) -> List[MeterResponse]:
    """
    API endpoint to run full retrieval and ranking pipeline
    
    Input: User context (current location, target location, preferences)
    Output: Returns JSON list of candidate meters
    """
    query = UserQuery(
        current_location=Location(lat=lat, lon=lon),
        current_time=datetime.now(timezone.utc),
        target_location_address=destination,
        preferences=UserPreferences(
            budget_range=BudgetRange[budget.upper()],
            stay_time=StayTime[stay.upper()],
        ),
    )

    # Search for raw meters from ladot client
    results = run_search_pipeline(query, top_k=top_k)

    return [
        MeterResponse(
            spaceid=m.spaceid,
            address=m.address,
            rate_per_hour=m.rate_per_hour,
            time_limit_minutes=m.time_limit_minutes,
            occupancy=m.occupancy.value,
            distance_to_destination_meters=m.distance_to_destination_meters,
            walk_time_minutes=m.walk_time_minutes,
            estimated_total_cost=m.estimated_total_cost,
            rank=m.rank,
        )
        for m in results
    ]