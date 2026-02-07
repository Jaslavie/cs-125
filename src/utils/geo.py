import pygeohash as pgh
from typing import List

from src.constants.constants import DEFAULT_GEOHASH_PRECISION
from src.models import RawMeterInventory

def get_distance():
    """
    Returns distance to destination
    """
    pass

def encode_geohash(latitude: str, longitude: str, precision: int = DEFAULT_GEOHASH_PRECISION):
    """
    Get geohash of the location based on the latlong
    Algorithm will find close meters based on this geohash
    """
    geohash = pgh.encode(latitude=latitude, longitude=longitude, precision = precision)
    return geohash

class GeoIndex:
    """
    Group meters by geohash cell(s)
    Index meters by the geohash cell id it is within
    This is the first filtering step to limit our search space

    Returns: { geohash: List[Meters] }
    """
    def __init__(self, precision: int = DEFAULT_GEOHASH_PRECISION):
        """
        Initialize persistent inverted index for the user session
        """
        self.precision = precision
        self.geohash_inverted_index: dict[str, list[RawMeterInventory]] = {} 
        self.seen_meters: set[str] = set() # enforce uniqueness
    
    def add_meters_to_geohash(self, meters: list[RawMeterInventory]) -> int:
        """
        Add a meter to a geohash index
        """
        added = 0

        for meter in meters:
            # Skip if meter already exists in inverted index list
            if meter.spaceid in self.seen_meters:
                continue

            # Create new geohash
            gh = encode_geohash(
                float(meter.latlng.latitude),
                float(meter.latlng.longitude),
                self.precision
            )

            # Create a new inverted index
            # indexed by geohash
            if gh not in self.geohash_inverted_index:
                self.geohash_inverted_index[gh] = []
            self.geohash_inverted_index[gh].append(meter)
            self.seen_meters.add(meter.spaceid)
            added += 1
        
        print(f"Added {added} new meters")
        return added

    def get_meters_in_geohash(
        self, 
        latitude: float, 
        longitude: float
    ) -> List[RawMeterInventory]:
        """
        Returns all indexed meters in the target cell
        Lookup for neighbors around cell
        Use the inverted index
        """
        gh = encode_geohash(latitude, longitude, self.precision)

        # Lookup the 8 neighboring grids
        # Find the meters within this 1 mile radius
        # Lookup occurs at query time
        top = pgh.get_adjacent(gh, "top")
        bottom = pgh.get_adjacent(gh, "bottom")
        
        # Concatenate main grid cell and surrounding ones
        cells_to_check = [
            gh,
            top,
            pgh.get_adjacent(top, "left"),
            pgh.get_adjacent(top, "right"),
            bottom,
            pgh.get_adjacent(bottom, "left"),
            pgh.get_adjacent(bottom, "right"),
            pgh.get_adjacent(gh, "left"),
            pgh.get_adjacent(gh, "right"),
        ]
        
        # Check each cell and add to results list
        results: List[RawMeterInventory] = []
        for cell in cells_to_check:
            meters = self.geohash_inverted_index.get(cell, [])
            results.extend(meters)

        return results

# Create a singleton instance
# Ensures that index list will 
# persist through the user session
geo_index = GeoIndex()

