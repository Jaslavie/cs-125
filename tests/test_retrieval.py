"""
Unit tests to test data processing and retrieval
NOTE: THIS CODE WAS GENERATED WITH CLAUDE 4.6
"""
import pytest
from datetime import datetime
from src.utils.geo import encode_geohash, GeoIndex
from src.models import RawMeterInventory, RawLatLng, RawMeterOccupancy
from src.models.user import UserQuery, Location, UserPreferences, BudgetRange, StayTime
from src.models.meter import CandidateMeter, OccupancyStatus

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
    assert len(gh) == 6  # matches DEFAULT_GEOHASH_PRECISION = 6


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
# walk to your destination from it. The 9-cell neighbor grid at precision 6
# (~1 mile radius) is the deliberate cutoff. Beyond that → return nothing
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
    User's own cell has zero meters, but one meter sits ~1.5 km away in an
    adjacent geohash cell. Neighbor lookup should still surface it.
    Real scenario: you're on a residential block; metered street is several
    blocks over.
    """
    index = GeoIndex()
    # Meter on Vine St (Hollywood)
    index.add_meters_to_geohash([METER_HO453])

    # Query from ~600m south — in a neighbor cell at precision 6
    user_lat, user_lon = 34.098, -118.325527
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
    # ~500m north and ~500m south of query point — different cells at precision 6
    meter_north = _make_meter("BND_N", "34.108", "-118.327")
    meter_south = _make_meter("BND_S", "34.098", "-118.327")
    index.add_meters_to_geohash([meter_north, meter_south])

    # Verify precondition: all three points land in different cells
    query_gh = encode_geohash(34.103, -118.327)
    north_gh = encode_geohash(34.108, -118.327)
    south_gh = encode_geohash(34.098, -118.327)
    assert len({query_gh, north_gh, south_gh}) == 3, "Test setup: need 3 distinct cells"

    results = index.get_meters_in_geohash(34.103, -118.327)
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


# ---------------------------------------------------------------------------
# Full pipeline integration test
# ---------------------------------------------------------------------------

def test_full_pipeline(monkeypatch):
    """
    End-to-end: search_meters() geocodes → fetches → indexes → cleans → filters.
    All external services (LADOT API, geocoding) are mocked.
    """
    from src.services.retrieval import search_meters

    # ── Fake raw meters (close together so they land in the same geohash cells) ──
    fake_meters = [
        RawMeterInventory(
            spaceid="P01", blockface="100 MAIN ST", metertype="Single-Space",
            ratetype="TOD", raterange="$2.00 - $3.00", timelimit="2HR",
            latlng=RawLatLng(latitude="34.1020", longitude="-118.3260"),
        ),
        RawMeterInventory(
            spaceid="P02", blockface="200 MAIN ST", metertype="Single-Space",
            ratetype="FLAT", raterange="$4.00", timelimit="30MIN",
            latlng=RawLatLng(latitude="34.1021", longitude="-118.3261"),
        ),
        RawMeterInventory(
            spaceid="P03", blockface="300 MAIN ST", metertype="Single-Space",
            ratetype="FLAT", raterange="$1.50", timelimit="1HR",
            latlng=RawLatLng(latitude="34.1022", longitude="-118.3262"),
        ),
    ]

    # ── Fake occupancy: P01=VACANT, P02=OCCUPIED (should be filtered), P03=no record ──
    fake_occupancy = {
        "P01": RawMeterOccupancy(spaceid="P01", eventtime="2026-02-07T20:00:00.000", occupancystate="VACANT"),
        "P02": RawMeterOccupancy(spaceid="P02", eventtime="2026-02-07T20:00:00.000", occupancystate="OCCUPIED"),
    }

    # ── Mock all external calls ──
    monkeypatch.setattr("src.services.retrieval.address_to_lat_long", lambda addr: (34.1020, -118.3260))
    monkeypatch.setattr("src.services.retrieval.get_meters_in_area", lambda req: fake_meters)
    monkeypatch.setattr("src.services.retrieval.get_occupancy", lambda ids: fake_occupancy)
    # No need to mock reverse geocoding — parsers now uses blockface directly

    # Fresh geohash index so other tests don't interfere
    monkeypatch.setattr("src.services.retrieval.geo_index", GeoIndex())

    # ── Build a user query ──
    query = UserQuery(
        current_location=Location(lat=34.1020, lon=-118.3260),
        current_time=datetime(2026, 2, 7, 20, 0),
        target_location_address="Pantages Theatre, Hollywood",
        preferences=UserPreferences(budget_range=BudgetRange.MEDIUM, stay_time=StayTime.SHORT),
    )

    # ── Run pipeline ──
    results = search_meters(query)
    result_ids = {c.spaceid for c in results}

    # ── OCCUPIED meter filtered out, VACANT and UNKNOWN kept ──
    assert "P01" in result_ids, "VACANT meter should pass filter"
    assert "P02" not in result_ids, "OCCUPIED meter should be filtered out"
    assert "P03" in result_ids, "No occupancy record → UNKNOWN → should pass filter"

    # ── Verify parsed fields on a VACANT meter ──
    p01 = next(c for c in results if c.spaceid == "P01")
    assert p01.rate_per_hour == 2.5
    assert p01.time_limit_minutes == 120
    assert p01.occupancy == OccupancyStatus.VACANT
    assert p01.address == "100 MAIN ST"  # uses blockface directly

    # ── Verify parsed fields on an UNKNOWN meter ──
    p03 = next(c for c in results if c.spaceid == "P03")
    assert p03.rate_per_hour == 1.5
    assert p03.time_limit_minutes == 60
    assert p03.occupancy == OccupancyStatus.UNKNOWN