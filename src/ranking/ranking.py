"""
Ranking logic

ASSUMES VALID input ;; does not fetch data

MINDFUL: location, budget, time;
"""

from math import sin, cos, asin, sqrt, ceil, pi
from typing import List


from models.meter import CandidateMeter, OutputMeter
from models.user import UserPreferences, Location


##### helper functions



#computes the distance between 2 lat/long points in meters using haversine 
def distance_meters(a: Location, b: Location) -> float:
    R = 6_371_000  # Earth radius in meters

    def to_rad(d: float) -> float:
        return d * pi / 180

    d_lat = to_rad(b.lat - a.lat)
    d_lon = to_rad(b.lon - a.lon)
    lat1 = to_rad(a.lat)
    lat2 = to_rad(b.lat)

    h = (
        sin(d_lat / 2) ** 2
        + cos(lat1) * cos(lat2) * sin(d_lon / 2) ** 2
    )

    return 2 * R * asin(sqrt(h))




#convers user preferences into scored weights 
def get_weights(prefs: UserPreferences):
    return {
        "distance": 0.45 if prefs.walking_distance_preference == "close" else 0.3,
        "cost": 0.45 if prefs.budget_range_preference == "low" else 0.3,
        "time": 0.25 if prefs.stay_time_preference == "long" else 0.2,
    }




##### main logic -- rank candidate parking spots based on scores. 

def rank_parking_spots(candidates: List[CandidateMeter],destination: Location, user_prefs: UserPreferences) -> List[OutputMeter]:

    weights = get_weights(user_prefs)

    MAX_DISTANCE = 1000
    MAX_COST = 20
    IDEAL_TIME = 180

    scored = []
    #computes each parking spot:
    for spot in candidates:
        distance = spot.distance_to_destination_meters
        walk_time = spot.walk_time_minutes
        estimated_total_cost = spot.estimated_total_cost

        # normalize scores
        distance_score = 1 - min(distance / MAX_DISTANCE, 1)
        cost_score = 1 - min(estimated_total_cost / MAX_COST, 1)
        time_score = min(spot.time_limit_minutes / IDEAL_TIME, 1)

        score = (
            weights["distance"] * distance_score
            + weights["cost"] * cost_score
            + weights["time"] * time_score
        )

        scored.append({
            "spot": spot,
            "score": score
        })

    # sort scores
    scored.sort(key=lambda x: x["score"], reverse=True)

    # assign ranks and return top K! -- for now hardcoded to top 8
    results: List[OutputMeter] = []

    for rank, (_, spot) in enumerate(scored[:8], start=1):
        result = OutputMeter( 
            spaceid=spot.spaceid,
            address=spot.address,
            rate_per_hour=spot.rate_per_hour,
            time_limit_minutes=spot.time_limit_minutes,
            occupancy=spot.occupancy,
            distance_to_destination_meters=spot.distance_to_destination_meters,
            walk_time_minutes=spot.walk_time_minutes,
            estimated_total_cost=spot.estimated_total_cost,
            rank=rank
        )

        results.append(result)

    return results