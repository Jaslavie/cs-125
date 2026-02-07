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


# ---------------------------------------------------------------------------
# Edge cases: sparse distribution & the "how far is too far?" tradeoff
#
# Parking is hyper-local. Unlike a cafe search (Google shows results 10 mi
# away because you can drive there), a parking meter only matters if you can
# walk to your destination from it. The 9-cell neighbor grid at precision 7
# (~450 m radius) is the deliberate cutoff. Beyond that → return nothing
# and let the UI say "No meters nearby."
# ---------------------------------------------------------------------------

def _make_meter(spaceid: str, lat: str, lon: str) -> RawMeterInventory:
    """Minimal meter for edge-case tests."""
    return RawMeterInventory(
        spaceid=spaceid,
        blockface="",
        metertype="Single-Space",
        ratetype="FLAT",
        raterange="$1.00",
        timelimit="2HR",
        latlng=RawLatLng(latitude=lat, longitude=lon),
    )


def test_sparse_meter_in_neighbor_cell():
    """
    User's own cell has zero meters, but one meter sits ~200 m away in an
    adjacent geohash cell. Neighbor lookup should still surface it.
    Real scenario: you're on a residential block; metered street is one
    block over.
    """
    index = GeoIndex()
    # Meter on Vine St (Hollywood)
    index.add_meters_to_geohash([METER_HO453])

    # Query from ~200 m south — close enough to be in a neighbor cell
    # but NOT the same cell as HO453
    user_lat, user_lon = 34.101800, -118.325527
    user_gh = encode_geohash(user_lat, user_lon)
    meter_gh = encode_geohash(
        float(METER_HO453.latlng.latitude),
        float(METER_HO453.latlng.longitude),
    )
    # Precondition: they really are in different cells
    assert user_gh != meter_gh, "Test setup: user and meter should be in different cells"

    results = index.get_meters_in_geohash(user_lat, user_lon)
    assert any(m.spaceid == "HO453" for m in results)


def test_no_meters_within_walking_distance():
    """
    The only meter in the index is ~8 km away (downtown LA vs Hollywood).
    The 9-cell grid should NOT reach it → return empty.
    This is the Google Maps tradeoff: for cafes you'd still show a far
    result, but for parking it's useless — you can't walk 8 km to your car.
    """
    index = GeoIndex()
    # Meter in downtown LA
    downtown_meter = _make_meter("DT001", "34.0522", "-118.2437")
    index.add_meters_to_geohash([downtown_meter])

    # User is in Hollywood (~8 km north-west)
    results = index.get_meters_in_geohash(34.1017, -118.3261)
    assert results == []


def test_meters_across_geohash_boundary():
    """
    Two meters on opposite sides of the user, each in a different neighbor
    cell. Both should be returned — the 9-cell grid shouldn't create a
    blind spot in any direction.
    """
    index = GeoIndex()
    # ~220 m north and ~110 m south of query point, same longitude
    meter_north = _make_meter("BND_N", "34.1050", "-118.3270")
    meter_south = _make_meter("BND_S", "34.1020", "-118.3270")
    index.add_meters_to_geohash([meter_north, meter_south])

    # Verify precondition: all three points land in different cells
    query_gh = encode_geohash(34.1030, -118.3270)
    north_gh = encode_geohash(34.1050, -118.3270)
    south_gh = encode_geohash(34.1020, -118.3270)
    assert len({query_gh, north_gh, south_gh}) == 3, "Test setup: need 3 distinct cells"

    results = index.get_meters_in_geohash(34.1030, -118.3270)
    ids = {m.spaceid for m in results}
    assert "BND_N" in ids
    assert "BND_S" in ids


def test_cluster_in_adjacent_cell_all_returned():
    """
    User's cell is empty but 3 meters cluster in a single neighbor cell.
    All 3 should come back — don't stop after the first hit.
    """
    index = GeoIndex()
    # Three meters tightly clustered on one block
    cluster = [
        _make_meter("CL01", "34.103600", "-118.325500"),
        _make_meter("CL02", "34.103620", "-118.325510"),
        _make_meter("CL03", "34.103640", "-118.325520"),
    ]
    index.add_meters_to_geohash(cluster)

    # User ~200 m south, different cell
    results = index.get_meters_in_geohash(34.101800, -118.325500)
    ids = {m.spaceid for m in results}
    assert ids == {"CL01", "CL02", "CL03"}