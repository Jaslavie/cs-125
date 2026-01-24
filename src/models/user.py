"""
User data models
- Input user query
- User preferences
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum


@dataclass
class Location:
    lat: float
    lon: float


class BudgetRange(Enum):
    """
    User's budget preference category
    """
    LOW = "low"          # $0 - $10
    MEDIUM = "medium"    # $10 - $20
    HIGH = "high"        # $20+

    def to_max_dollars(self) -> float:
        return {
            BudgetRange.LOW: 10.0,
            BudgetRange.MEDIUM: 20.0,
            BudgetRange.HIGH: 50.0,
        }[self]


class WalkingDistance(Enum):
    """
    User's walking distance preference category
    """
    CLOSE = "close"      # 0 - 200m
    MEDIUM = "medium"    # 200 - 400m
    FAR = "far"          # 400m+

    def to_max_meters(self) -> int:
        return {
            WalkingDistance.CLOSE: 200,
            WalkingDistance.MEDIUM: 400,
            WalkingDistance.FAR: 800,
        }[self]


class StayTime(Enum):
    """
    User's intended parking duration category
    """
    SHORT = "short"      # 0 - 60 min
    MEDIUM = "medium"    # 60 - 120 min
    LONG = "long"        # 120+ min

    def to_minutes(self) -> int:
        return {
            StayTime.SHORT: 60,
            StayTime.MEDIUM: 120,
            StayTime.LONG: 240,
        }[self]


@dataclass
class UserPreferences:
    """
    Combined user preferences
    """
    budget_range: BudgetRange
    walking_distance: WalkingDistance
    stay_time: StayTime


@dataclass
class UserQuery:
    """
    User input for a single parking search query.
    Combines context with stored preferences
    """
    target_location: str          # Free text, e.g. "Pantages Theatre"
    current_location: Location    # From device GPS
    current_time: datetime        # Auto-captured
    preferences: UserPreferences


@dataclass
class UserLocationRadius:
    """
    Computed meters within radius of the user
    """
    lat: float
    lon: float
    radius: float # meters