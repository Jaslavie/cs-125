# test_osrm.py
# Run from project root: python test_osrm.py

from src.models.user import Location
from src.services.api_distance import get_walking_route

# Two real Hollywood LA coordinates
# Meter location: Hollywood & Vine area
meter_location = Location(lat=34.1016, lon=-118.3267)

# Destination: Hollywood Bowl area
destination = Location(lat=34.1122, lon=-118.3390)

print("Testing OSRM walking route...\n")

route = get_walking_route(meter_location, destination)

print(f"  Distance : {route['distance_meters']:.0f} m")
print(f"  Duration : {route['duration_seconds']:.0f} s")
print(f"  Walk time: {route['walk_time_minutes']} min")
print(f"  Source   : {route['source']}")

if route["source"] == "osrm":
    print("\n✅ OSRM is working correctly!")
else:
    print("\n⚠️  Fell back to Haversine — check your internet connection.")