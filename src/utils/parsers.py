"""
Clean raw API data and format it to 
CandidateMeter schema
"""
import re
from datetime import datetime
from typing import Optional

from src.models.user import Location
from src.models.meter import CandidateMeter, OccupancyStatus
from src.models.raw_api import RawMeterInventory, RawMeterOccupancy
from src.clients.geocoding_client import lat_long_to_address

def clean_data(
    raw_inventory: RawMeterInventory,
    raw_occupancy: Optional[RawMeterOccupancy] = None,
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
    address = lat_long_to_address(location.lat, location.lon)

    # Get hourly range
    amounts = re.findall(r"\$(\d+\.?\d*)", raterange)
    if len(amounts) >= 2:
        rate_per_hour = (float(amounts[0]), float(amounts[-1]))
    elif len(amounts) == 1:
        rate_per_hour = (float(amounts[0]), float(amounts[0]))
    else:
        rate_per_hour = (0.0, 0.0)

    # Get time limit
    match = re.match(r"(\d+)\s*(HR|MIN)", timelimit.strip().upper())
    if match and match.group(2) == "HR":
        time_limit_minutes = int(match.group(1)) * 60
    elif match and match.group(2) == "MIN":
        time_limit_minutes = int(match.group(1))
    else:
        time_limit_minutes = 0

    # Get occupancy state
    try:
        occupancy = OccupancyStatus(raw_occupancy_state.upper())
    except (ValueError, AttributeError):
        occupancy = OccupancyStatus.UNKNOWN

    # Get event time
    try:
        occupancy_time = datetime.fromisoformat(raw_event_time) if raw_event_time else None
    except ValueError:
        occupancy_time = None

    return CandidateMeter(
        spaceid=spaceid,
        metertype=metertype,
        location=location,
        address=address,
        rate_per_hour=rate_per_hour,
        time_limit_minutes=time_limit_minutes,
        occupancy=occupancy,
        occupancy_time=occupancy_time,
    )
