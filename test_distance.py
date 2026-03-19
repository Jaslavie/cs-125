# test_distance.py
# Run from project root: python3 test_distance.py

from src.models.user import Location
from src.services.api_distance import get_walking_route
from src.utils.haversine import haversine_distance

# Destination: Hollywood Bowl area
destination = Location(lat=34.1122, lon=-118.3390)

# Simulate 50 candidate meter locations around Hollywood
import random
random.seed(42)
candidates = [
    Location(
        lat=34.1016 + random.uniform(-0.02, 0.02),
        lon=-118.3267 + random.uniform(-0.02, 0.02)
    )
    for _ in range(50)
]

print(f"Total candidates: {len(candidates)}")
print("=" * 40)

# --- Step 1: Haversine pre-filter ---
print("\nStep 1: Ranking all candidates by Haversine distance...")
haversine_ranked = sorted(
    candidates,
    key=lambda loc: haversine_distance(loc, destination)
)
top_30 = haversine_ranked[:30]
print(f"  Top 30 selected out of {len(candidates)} candidates")
print(f"  Closest (Haversine): {haversine_distance(top_30[0], destination):.0f} m")
print(f"  30th closest (Haversine): {haversine_distance(top_30[-1], destination):.0f} m")
print(f"  Furthest excluded (Haversine): {haversine_distance(haversine_ranked[30], destination):.0f} m")

# --- Step 2: OSRM calls on top 30 only ---
print(f"\nStep 2: Making OSRM calls for top {len(top_30)} candidates...")
osrm_count = 0
fallback_count = 0

for i, loc in enumerate(top_30):
    route = get_walking_route(loc, destination)
    if route["source"] == "osrm":
        osrm_count += 1
    else:
        fallback_count += 1
    if i < 3:  # show first 3 results as sample
        print(f"  [{i+1}] Distance: {route['distance_meters']:.0f} m | Walk: {route['walk_time_minutes']} min | Source: {route['source']}")

print(f"\nResults:")
print(f"  OSRM responses : {osrm_count}")
print(f"  Haversine fallbacks: {fallback_count}")

if osrm_count == len(top_30):
    print("\n 2-step approach working correctly — OSRM called for top 30 only!")
elif osrm_count > 0:
    print(f"\n Partial success — {fallback_count} fallbacks, check internet connection.")
else:
    print("\n All calls fell back to Haversine — check internet connection.")