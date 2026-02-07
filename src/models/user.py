"""
User data models
- Input user query
- User preferences
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pydantic import BaseModel

@dataclass
class Location:
    lat: float
    lon: float

class BudgetRange(Enum):
    """
    User's budget preference category
    In dollars
    """
    LOW = (0, 10)
    MEDIUM = (10, 20)
    HIGH = (20, 50)

class StayTime(Enum):
    """
    User's intended parking duration category
    In minutes
    """
    SHORT = (0, 60)
    MEDIUM = (60, 120)
    LONG = (120, 240)

@dataclass
class UserPreferences:
    """
    Combined user preferences
    """
    budget_range: BudgetRange
    stay_time: StayTime

class MeterSearchRequest(BaseModel):
    """
    Passed into the search body of the ladot api
    """
    lat: float # destination latitude
    lon: float # destination longitude
    radius_m: float = 1609.34  # 1 mile in meters

@dataclass
class UserQuery:
    """
    Cleaned User input for a single parking search query.
    Combines context with stored preferences
    """
    # Auto computed
    current_location: Location
    current_time: datetime
    # Defined by user
    target_location_address: str
    preferences: UserPreferences


@dataclass
class UserLocationRadius:
    """
    Computed meters within radius of the user
    """
    lat: float
    lon: float
    radius: float