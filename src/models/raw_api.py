"""
Raw API response models from LADOT endpoints.
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
    # Core fields
    spaceid: str              # "SVV434" - unique meter ID
    blockface: str            # "800 HELIOTROPE DR" - street address
    metertype: str            # "Single-Space" - physical meter type
    ratetype: str             # "JUMP" - pricing algorithm/zone
    raterange: str            # "$1.5/H - $6/6H" - price range (needs parsing)
    timelimit: str            # "6HR" - max parking duration (needs parsing)
    latlng: RawLatLng

    # Socrata computed region fields (auto-generated from lat/lng)
    # These are Optional since they may not always be present
    computed_region_qz3q_ghft: Optional[str] = None  # Neighborhood Council district
    computed_region_k96s_3jcv: Optional[str] = None  # City Council district
    computed_region_tatf_ua23: Optional[str] = None  # Census tract
    computed_region_ur2y_g4cx: Optional[str] = None  # Planning area
    computed_region_kqwf_mjcx: Optional[str] = None  # Service region
    computed_region_2dna_qi2s: Optional[str] = None  # Municipal zone (unknown)


@dataclass
class RawMeterOccupancy:
    """
    Raw response from LADOT Meter Occupancy API.
    Endpoint: https://data.lacity.org/resource/e7h6-4a3e.json
    """
    spaceid: str              # "HO523C"
    eventtime: str            # "2026-01-24T19:03:24.000" - ISO 8601 string
    occupancystate: str       # "VACANT" or "OCCUPIED"
