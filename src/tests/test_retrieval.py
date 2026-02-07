"""
Unit tests to test data processing and retrieval
NOTE: THIS CODE WAS GENERATED WITH CLAUDE 4.6
"""
import pytest
from src.utils.geo import encode_geohash, GeoIndex
from src.models import RawMeterInventory, RawLatLng

# Real meters from the LADOT API (Hollywood area)
METER_HO453 = RawMeterInventory(
    spaceid="HO453",
    blockface="1700 VINE ST",
    metertype="Single-Space",
    ratetype="TOD",
    raterange="$1.50 - $3.00",
    timelimit="2HR",
    latlng=RawLatLng(latitude="34.103638", longitude="-118.325527")
)

METER_SV881 = RawMeterInventory(
    spaceid="SV881",
    blockface="1400 VINE ST",
    metertype="Single-Space",
    ratetype="FLAT",
    raterange="$1.00",
    timelimit="2HR",
    latlng=RawLatLng(latitude="34.096643", longitude="-118.326532")
)

METER_HO629 = RawMeterInventory(
    spaceid="HO629",
    blockface="1701 WILCOX AVE",
    metertype="Single-Space",
    ratetype="TOD",
    raterange="$0.50 - $3.00",
    timelimit="2HR",
    latlng=RawLatLng(latitude="34.102329", longitude="-118.331113")
)

def test_encode_returns_string_of_correct_length():
    gh = encode_geohash(34.1017, -118.3261)
    assert isinstance(gh, str)
    assert len(gh) == 7  # matches your DEFAULT_GEOHASH_PRECISION = 7


def test_nearby_points_same_cell():
    """Two points ~50m apart should land in the same cell at precision 7."""
    gh1 = encode_geohash(34.1017, -118.3261)
    gh2 = encode_geohash(34.1017, -118.3262)
    assert gh1 == gh2


def test_add_meters_to_geohash_skips_duplicates():
    index = GeoIndex()
    assert index.add_meters_to_geohash([METER_HO453]) == 1
    assert index.add_meters_to_geohash([METER_HO453]) == 0


def test_get_meters_in_geohash_returns_indexed_meters():
    index = GeoIndex()
    index.add_meters_to_geohash([METER_HO453, METER_SV881])
    results = index.get_meters_in_geohash(34.103638, -118.325527)
    ids = {m.spaceid for m in results}
    assert "HO453" in ids


def test_get_meters_in_geohash_empty_index():
    index = GeoIndex()
    assert index.get_meters_in_geohash(34.1017, -118.3261) == []