"""
Normalized Meter data model
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional

from .user import Location


class OccupancyStatus(Enum):
    VACANT = "VACANT"
    OCCUPIED = "OCCUPIED"
    UNKNOWN = "UNKNOWN"


@dataclass
class Meter:
    """
    Combined Meter object from /ladot-meters and /ladot-occupancy
    """
    # Identity
    spaceid: str                  # "HO108"

    # Location
    location: Location            # Parsed from string lat/lng
    address: str                  # "800 HELIOTROPE DR" (from blockface)

    # Pricing & rules
    rate_per_hour: float          # 1.50 (parsed from "$1.5/H - $6/6H")
    time_limit_minutes: int       # 360 (parsed from "6HR")

    # Real-time status
    occupancy: OccupancyStatus
    last_updated: Optional[datetime]  # From occupancy API eventtime

    # Optional regional data (from Socrata computed fields)
    neighborhood_council: Optional[str] = None
    city_council_district: Optional[str] = None
    census_tract: Optional[str] = None

@dataclass
class CandidateMeter:
    """
    A parking meter enriched with computed fields for scoring.
    """
    # Base meter data
    spaceid: str
    location: Location
    address: str
    rate_per_hour: float
    time_limit_minutes: int
    occupancy: OccupancyStatus

    # Computed fields (calculated during retrieval)
    distance_to_destination_meters: float
    walk_time_minutes: int
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