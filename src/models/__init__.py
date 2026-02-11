"""
Initialize data models

Models:
- raw_api: Raw API response shapes (strings, unprocessed)
- user: User query and preferences as user context
- meter: Normalized meter Object, and Enriched Meter object for scoring
"""

from .raw_api import RawLatLng, RawMeterInventory, RawMeterOccupancy
from .user import Location, BudgetRange, StayTime, UserPreferences, UserQuery, MeterSearchRequest
from .meter import OccupancyStatus, CandidateMeter

__all__ = [
    # Raw API
    "RawLatLng",
    "RawMeterInventory",
    "RawMeterOccupancy",
    # User
    "Location",
    "BudgetRange",
    "StayTime",
    "UserPreferences",
    "UserQuery",
    "MeterSearchRequest",
    # Meter
    "OccupancyStatus",
    "CandidateMeter",
]
