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
    distance_meters: float        # Haversine distance to destination
    walk_time_minutes: int        # distance / 80 m/min
    estimated_total_cost: float   # rate × (duration / 60) 

    @classmethod
    def from_meter(
        cls,
        meter: Meter,
        destination: Location,
        stay_duration_minutes: int
    ) -> "CandidateMeter":
        """
        Create a Candidate spot with Meter data

        Args:
            meter: The base meter data
            destination: User's target location (for distance calc)
            stay_duration_minutes: How long user plans to park

        Returns:
            CandidateSpot with all computed fields populated
        """
        from ..utils.geo import haversine_distance

        distance = haversine_distance(meter.location, destination)
        walk_time = int(distance / 80)  # avg walking speed ~80 m/min
        total_cost = meter.rate_per_hour * (stay_duration_minutes / 60)

        return cls(
            spaceid=meter.spaceid,
            location=meter.location,
            address=meter.address,
            rate_per_hour=meter.rate_per_hour,
            time_limit_minutes=meter.time_limit_minutes,
            occupancy=meter.occupancy,
            distance_meters=distance,
            walk_time_minutes=walk_time,
            estimated_total_cost=total_cost,
        )