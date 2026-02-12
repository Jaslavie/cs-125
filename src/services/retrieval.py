"""
Retrieval orchestrator
Manages full pipeline to retrieve and return meters to the client:
- Ingest user query
- Fetch meters via API or geohash index
- Clean raw data and create candidate meters
- Ingest user context
- Score and rank
- Return top k results
"""
from src.models.user import UserQuery, Location, MeterSearchRequest
from src.models.meter import CandidateMeter, OutputMeter, OccupancyStatus
from src.models.raw_api import RawMeterInventory
from src.clients.geocoding_client import address_to_lat_long
from src.clients.ladot_client import get_meters_in_area, get_occupancy
from src.utils.geo import geo_index
from src.utils.parsers import clean_data
from src.services.ranking import MeterRanker

def search_meters(
    user_query: UserQuery,
    top_k: int = 10, # TODO: define top k
) -> list[OutputMeter]:
    # Geocode selected target_location_address to latlong
    dest_lat, dest_long = address_to_lat_long(user_query.target_location_address)
    destination = Location(dest_lat, dest_long)

    # Fetch raw meters near dest from API
    # Only fetch within 1 mile radius to limit network query
    raw_meters = get_meters_in_area(
        MeterSearchRequest(lat=destination.lat, lon=destination.lon, radius_m=1609.34)
    )

    # Build local geohash cache to index into
    # Indexes into the geohash to find the 
    # geohash meters are located in
    geo_index.add_meters_to_geohash(raw_meters)

    # Narrow filter to 9 geohash grid cells
    nearby_raw: list[RawMeterInventory] = geo_index.get_meters_in_geohash(
        destination.lat, destination.lon
    )

    # Try to get occupancy for all candidate meters
    spaceids = [m.spaceid for m in nearby_raw]
    occupancy_map = get_occupancy(spaceids)

    # Create candidate meters
    # First, filter all candidates that have taken occupancy
    candidates : list[CandidateMeter] = []
    for raw_meter in nearby_raw:
        occ = occupancy_map.get(raw_meter.spaceid)
        candidate = clean_data(raw_meter, occ)
        candidates.append(candidate)

    # Filter out occupied meters
    candidates = [c for c in candidates if c.occupancy != OccupancyStatus.OCCUPIED]

    # TODO: Implement scoring
    # ranked = score(candidates, user_query)
    # return ranked[:top_k]
    # return candidates
    ranker = MeterRanker()
    ranked = ranker.rank_meters(candidates, user_query, destination, top_k)
    return ranked