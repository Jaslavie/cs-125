"""
Meter data models
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional
import datetime

from .user import Location
from .raw_api import RawLatLng


class OccupancyStatus(Enum):
    VACANT = "VACANT"
    OCCUPIED = "OCCUPIED"
    UNKNOWN = "UNKNOWN"

@dataclass
class CandidateMeter:
    """
    Cleaned parking meter data
    Prepared for scoring and ranking
    Only include data intrinsic to the meter
    """
    # Meter data
    spaceid: str        # Directly from raw api
    metertype: str      # Directly from raw api
    location: Location  # LATLONG
    address: str        # Full address
    rate_per_hour: tuple[float, float] # (4, 5) = $4-$5
    time_limit_minutes: int # 60 mins

    # Occupancy data
    occupancy: OccupancyStatus  # VACANT / OCCUPIED / UNKNOWN
    occupancy_time: Optional[datetime.datetime] = None

@dataclass
class OutputMeter:
    """
    Final output meter shown to user
    We will show the computed metrics here 
    relative to the user's inputs (ex: walking distance)
    """ 
    # From meter data
    spaceid: str
    address: str
    rate_per_hour: float
    time_limit_minutes: int
    occupancy: OccupancyStatus
    
    # Location for map display
    latitude: float
    longitude: float

    # Computed metrics
    distance_to_destination_meters: float
    walk_time_minutes: int
    estimated_total_cost: float

    # Ranking output
    rank: int