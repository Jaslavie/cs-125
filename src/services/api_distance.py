
"""
OSRM is an api routing client to get a realistic walking distance 
that considers pedestrian walks ways, etc. Uses the public demo server
so no API key is required. 
"""

import requests
import logging
from src.models.user import Location
from src.utils.haversine import haversine_distance
logger = logging.getLogger(__name__)

OSRM_BASE_URL = "http://router.project-osrm.org/route/v1/foot"
REQUEST_TIMEOUT_SECONDS = 5


def get_walking_route(origin: Location, destination: Location) -> dict:
    """
    Get walking distance and duration between two points via OSRM.

    Returns a dict with:
        - distance_meters (float): actual walking path distance
        - duration_seconds (float): estimated walking time
        - walk_time_minutes (int): duration_seconds rounded to nearest minute
        - source (str): "osrm" or "haversine" (fallback)
    """
    url = (
        f"{OSRM_BASE_URL}"
        f"/{origin.lon},{origin.lat}"
        f";{destination.lon},{destination.lat}"
        f"?overview=false"
    )

    try:
        response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
        data = response.json()

        if data.get("code") != "Ok" or not data.get("routes"):
            logger.warning("OSRM returned no routes; falling back to Haversine.")
            return _haversine_fallback(origin, destination)

        route = data["routes"][0]
        distance_meters = route["distance"]

        # Use realistic walking speed instead of OSRM's duration (can be inaccurate)
        WALKING_SPEED_MPS = 1.3  # ~80 m/min
        realistic_duration = distance_meters / WALKING_SPEED_MPS

        return {
            "distance_meters": distance_meters,
            "duration_seconds": realistic_duration,
            "walk_time_minutes": max(1, round(realistic_duration / 60)),
            "source": "osrm",
        }

    except requests.exceptions.Timeout:
        logger.warning("OSRM request timed out; falling back to Haversine.")
        return _haversine_fallback(origin, destination)

    except requests.exceptions.RequestException as e:
        logger.warning(f"OSRM request failed ({e}); falling back to Haversine.")
        return _haversine_fallback(origin, destination)


def _haversine_fallback(origin: Location, destination: Location) -> dict:
    """this is a fall back function just in case api call errors out"""
    distance_meters = haversine_distance(origin, destination)
    duration_seconds = (distance_meters / 80) * 60  # 80 m/min

    return {
        "distance_meters": distance_meters,
        "duration_seconds": duration_seconds,
        "walk_time_minutes": max(1, round(duration_seconds / 60)),
        "source": "haversine",
    }