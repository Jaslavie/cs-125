import os
from dotenv import load_dotenv
import psycopg2

from src.models.meter import CandidateMeter

load_dotenv()

def connect_to_db(db_url: str):
    """
    Client to connect to the Supabase Postgres 
    via python-to-sql adapter
    """
    try:
        supabase_url = os.getenv("SUPABASE_CONNECTION_STRING")
        return psycopg2.connect(db_url)
    except Exception as e:
        logger.exception("Unexpected error while connecting to DB")
        raise

def upsert_meter(cur, meter: CandidateMeter) -> None:
    """
    Insert/Update a candidate meter to the Meters table
    Update all fields on conflict

    Input: 
    - cur (cursor): sends queries through connection
    - meter: target object to insert or update in db
    """
    # Adapter sends SQL string to db server (postgres)
    # Attempts INSERT with preset %s as placeholder values
    # If there's an existing spaceid, overwrite original field with new value
    cur.execute(
        # SQL query
        """
        INSERT INTO meters (
            spaceid, metertype, lat, lon, address,
            rate_min, rate_max, time_limit_minutes,
            occupancy, occupancy_time, updated_at
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (spaceid) DO UPDATE SET
            metertype          = EXCLUDED.metertype,
            lat                = EXCLUDED.lat,
            lon                = EXCLUDED.lon,
            address            = EXCLUDED.address,
            rate_min           = EXCLUDED.rate_min,
            rate_max           = EXCLUDED.rate_max,
            time_limit_minutes = EXCLUDED.time_limit_minutes,
            occupancy          = EXCLUDED.occupancy,
            occupancy_time     = EXCLUDED.occupancy_time,
            updated_at         = EXCLUDED.updated_at
        """,
        # values to insert
        (
            meter.spaceid,
            meter.metertype,
            meter.location.lat,
            meter.location.lon,
            meter.address,
            meter.rate_per_hour[0],       # rate_min in table
            meter.rate_per_hour[1],       # rate_max in table
            meter.time_limit_minutes,
            meter.occupancy.value,        # store enum as string
            meter.occupancy_time,
            datetime.now(timezone.utc),
        ),
    )
