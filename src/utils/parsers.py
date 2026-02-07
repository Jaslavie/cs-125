"""
Clean raw API data and format it to 
CandidateMeter schema
"""
from src.models.meter import OccupancyStatus
from src.models.raw_api import RawMeterInventory, RawMeterOccupancy
from src.clients.geocoding_client import lat_long_to_address

def clean_data(
    raw_inventory:RawMeterInventory,
    raw_occupancy: RawMeterOccupancy,
) -> CandidateMeter:
    # Unpack
    spaceid = raw_inventory.spaceid
    metertype = raw_inventory.metertype
    raterange = raw_inventory.raterange
    timelimit = raw_inventory.timelimit
    raw_lat = raw_inventory.latlng.latitude
    raw_lon = raw_inventory.latlng.longitude

    raw_occupancy_state = raw_occupancy.occupancystate if raw_occupancy else ""
    raw_event_time = raw_occupancy.eventtime if raw_occupancy else ""
    
    # Normalize address
    location = Location(lat=float(raw_lat), lon=float(raw_lon))

    # Get full address
    normalized_address = lat_long_to_address(location.lon, location.lat)

    # Get hourly range
    amounts = re.findall(r"\$(\d+\.?\d*)", raterange)
    normalized_hourly_rate = (float(amounts[0]), gloat(amounts[1]))

    # Get time limit
    time_limit_minutes = re.match(r"(\d+)\s*(HR)", timelimit.strip().upper())
    if match and match.group(2) == "HR":
        time_limit_minutes = int(match.group(1)) * 60
    if match and match.group(2) == "MIN":
        time_limit_minutes = int(match.group(1))
    else:
        time_limit_minutes = 0
    
    # Parse occupancy str and time
    try:
        occupancy = OccupancyStatus(raw_occupancy_state.upper())
    except (ValueError, AttributeError):
        occupancy = OccupancyStatus.UNKNOWN
    
    try:
        occupancy_time = datetime.fromisoformat(raw_event_time) if raw_event_time else None
    except ValueError:
        occupancy_time = None
    
    return {
        spaceid: spaceid,
        location: location,
        address: normalized_address,
        rate_per_hour: normalized_hourly_rate,
        time_limit_minutes: normalized_time_limit
        occupancy: normalized_occupancy,
        occupancy_time=occupancy_time,
        walk_time_minutes: 0, # TODO: This needs to be computed based on user context
        walk_time_distance_miles: 0.0,
        estimated_total_cost: 0.0 # TODO: This needs to be computed based on user context
    }
