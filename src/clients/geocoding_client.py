import ssl
import certifi
from geopy.geocoders import Nominatim

# calling the Nominatim tool and create Nominatim class
# This is our main geocoding service
ssl_context = ssl.create_default_context(cafile=certifi.where())
loc = Nominatim(user_agent="petr-parking", ssl_context=ssl_context)

def address_to_lat_long(address: str):
    """
    Input: valid location string
    """
    # Convert address 
    getLoc = loc.geocode(address)
    latitude = getLoc.latitude
    longitude = getLoc.longitude
    return latitude, longitude

# def get_user_location_radius(userLocation: Location):
#     {lat, long} = userLocation 

result = address_to_lat_long("New York City")
print(result)