from src.models.user import Location

def haversine_distance(loc1: Location, loc2: Location) -> float:
    """Calculate distance between two lat/long points in meters"""
    from math import radians, sin, cos, sqrt, atan2
    
    R = 6371000  # Earth radius in meters
    
    lat1, lon1 = radians(loc1.lat), radians(loc1.lon)
    lat2, lon2 = radians(loc2.lat), radians(loc2.lon)
    
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    return R * c 