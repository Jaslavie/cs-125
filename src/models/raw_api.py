"""
Raw API response models for LADOT endpoints.
These match the exact shape of data returned by the APIs.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class RawLatLng:
    """
    Nested lat/lng object from inventory API.
    """
    latitude: str   # "34.086629"
    longitude: str  # "-118.294872"

@dataclass
class RawMeterInventory:
    """
    Raw response from LADOT Meter Inventory API.
    Endpoint: https://data.lacity.org/resource/s49e-q6j2.json
    """
    spaceid: str              # "SVV434"
    blockface: str            # "800 HELIOTROPE DR"
    metertype: str            # "Single-Space"
    ratetype: str             # "JUMP"
    raterange: str            # "$1.5/H - $6/6H"
    timelimit: str            # "6HR"
    latlng: RawLatLng


@dataclass
class RawMeterOccupancy:
    """
    Raw response from LADOT Meter Occupancy API.
    Endpoint: https://data.lacity.org/resource/e7h6-4a3e.json
    """
    spaceid: str              # "HO523C"
    eventtime: str            # "2026-01-24T19:03:24.000" - ISO 8601 string
    occupancystate: str       # "VACANT" or "OCCUPIED"
