from datetime import datetime

from src.ranking.ranking import rank_parking_spots
from src.models.meter import CandidateMeter, OccupancyStatus
from src.models.user import Location, UserPreferences, BudgetRange, StayTime

print("test running...")

# --------------------------------------------------
# destination (equivalent to TS destination)
# --------------------------------------------------
destination = Location(lat=34.100, lon=-118.324)

# --------------------------------------------------
# candidate meters (equivalent to TS spots[])
# NOTE: distance / walk time / cost are PRECOMPUTED
# --------------------------------------------------
spots = [
    CandidateMeter(
        spaceid="CLOSE",
        location=Location(lat=34.1005, lon=-118.324),
        address="CLOSE ST",
        rate_per_hour=3.0,
        time_limit_minutes=120,
        occupancy=OccupancyStatus.VACANT,
        distance_to_destination_meters=50,
        walk_time_minutes=1,
        estimated_total_cost=6.0
    ),
    CandidateMeter(
        spaceid="FAR",
        location=Location(lat=34.110, lon=-118.335),
        address="FAR ST",
        rate_per_hour=1.0,
        time_limit_minutes=240,
        occupancy=OccupancyStatus.VACANT,
        distance_to_destination_meters=1500,
        walk_time_minutes=19,
        estimated_total_cost=4.0
    )
]

# --------------------------------------------------
# user preferences (MATCHES src/models/user.py EXACTLY)
# --------------------------------------------------
prefs = UserPreferences(
    budget_range=BudgetRange.MEDIUM,
    stay_time=StayTime.MEDIUM
)

# --------------------------------------------------
# run ranking
# --------------------------------------------------
result = rank_parking_spots(spots, destination, prefs)

# --------------------------------------------------
# print table (JS console.table equivalent)
# --------------------------------------------------
print("\nResults:")
for r in result:
    print({
        "id": r.spaceid,
        "walkTime": r.walk_time_minutes,
        "cost": round(r.estimated_total_cost, 2),
        "rank": r.rank
    })

# --------------------------------------------------
# assertion
# --------------------------------------------------
if result[0].spaceid != "CLOSE":
    raise AssertionError("Test failed: CLOSE should rank first")

print("\nTest passed!")
