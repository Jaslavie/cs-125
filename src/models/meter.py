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
    Cleaned parking meter
    Prepared for scoring and ranking
    """
    # Meter data
    spaceid: str        # Directly from raw api
    metertype: str      # Directly from raw api
    location: Location  # LATLONG
    address: str        # Full address
    rate_per_hour: tuple[float, float] # (4, 5) = $4-$5
    time_limit_hours: int # 4 Hours

    # Occupancy data
    occupancy_time: datetime # datetime
    occupancy: OccupancyStatus # VACANT

    # Computed fields
    walk_time_minutes: int
    walk_time_distance_miles: float
    estimated_total_cost: float

@dataclass
class OutputMeter:
    """
    Final output meter shown to user
    """ 
    spaceid: str
    address: str
    rate_per_hour: float
    time_limit_minutes: int
    occupancy: OccupancyStatus
    distance_to_destination_meters: float
    walk_time_minutes: int
    estimated_total_cost: float

    # Ranking output
    rank: int