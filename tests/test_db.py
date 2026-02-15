"""
Tests for the FastAPI endpoints with TestClient
GENERATED WITH CLAUDE 4.6
"""
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from src.api import app
from src.models.meter import OutputMeter, OccupancyStatus

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_search_meters_returns_json():
    """
    Mock the pipeline and verify the endpoint returns proper JSON.
    """
    fake_output = [
        OutputMeter(
            spaceid="HO453",
            address="1700 VINE ST",
            rate_per_hour=2.25,
            time_limit_minutes=120,
            occupancy=OccupancyStatus.VACANT,
            distance_to_destination_meters=150.0,
            walk_time_minutes=2,
            estimated_total_cost=2.25,
            rank=1,
        )
    ]

    # Call api to run full search pipeline on user input
    with patch("src.api.run_search_pipeline", return_value=fake_output):
        response = client.get(
            "/meters/search",
            params={
                "lat": 34.1020,
                "lon": -118.3260,
                "destination": "Pantages Theatre",
                "budget": "MEDIUM",
                "stay": "SHORT",
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["spaceid"] == "HO453"
    assert data[0]["occupancy"] == "VACANT"
    assert data[0]["rate_per_hour"] == 2.25


def test_search_missing_required_params():
    """Omitting required params should return 422."""
    response = client.get("/meters/search")
    assert response.status_code == 422