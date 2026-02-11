import ssl
import certifi
from geopy.geocoders import Nominatim

from ..models.user import Location

# Makes HTTP call to the Nominatim tool and create Nominatim class
# This is our main geocoding service
ssl_context = ssl.create_default_context(cafile=certifi.where())
loc = Nominatim(user_agent="petr-parking", ssl_context=ssl_context)

def address_to_lat_long(address: str) -> Location:
    """
    Use cases:
    - Translate user desired destination to lat long
    - Translate user's current address into lat long
    Input: valid location string
    """
    # Convert address 
    getLoc = loc.geocode(address)
    latitude = getLoc.latitude
    longitude = getLoc.longitude
    return latitude, longitude

def lat_long_to_address(lat: float, long: float) -> str:
    """
    Translate lat long coords of a meter to address
    for user-facing application
    """
    geolocator = Nominatim(user_agent="meter-normalizer", ssl_context=ssl_context)
    location = geolocator.reverse((lat, long), zoom=18, addressdetails=True)
    return location.address if location else ""