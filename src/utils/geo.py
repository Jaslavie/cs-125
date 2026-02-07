import pygeohash as pgh
import .constants.constants

def get_distance()
    """
    Returns distance to destination
    """

def get_geohash(latitude: str, longitude: str):
    """
    Get geohash of the location based on the latlong
    Algorithm will find close meters based on this geohash
    """
    return pgh.encode(latitude=latitude, longitude=longitude)