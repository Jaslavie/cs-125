import ssl
import certifi
from geopy.geocoders import Nominatim

# Makes HTTP call to the Nominatim tool and create Nominatim class
# This is our main geocoding service
ssl_context = ssl.create_default_context(cafile=certifi.where())
loc = Nominatim(user_agent="petr-parking", ssl_context=ssl_context)

def address_to_lat_long(address: str) -> Location:
    """
    Input: valid location string
    """
    # Convert address 
    getLoc = loc.geocode(address)
    latitude = getLoc.latitude
    longitude = getLoc.longitude
    return latitude, longitude