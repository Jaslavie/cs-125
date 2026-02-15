import os
from dotenv import load_dotenv
import psycopg2
import datetime
import logging

from src.models.meter import CandidateMeter

logger = logging.getLogger(__name__)


def connect_to_db(db_url: str):
    """
    Client to connect to the Supabase Postgres 
    via python-to-sql adapter
    """
    try:
        return psycopg2.connect(db_url)
    except Exception as e:
        logger.exception("Unexpected error while connecting to DB")
        raise

def upsert_meter(cur, meter: CandidateMeter) -> None:
    """
    Helper to execute Insert/Update on a candidate meter in the Meters table
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
            datetime.datetime.now(datetime.timezone.utc),
        ),
    )

def batch_upsert_meters(supabase_url:str, meters: list[CandidateMeter]) -> int:
    """
    Manages batch insertions into the db
    retrieval pipeline will call for all db transactions

    Return: number of meters inserted
    """
    conn = connect_to_db(supabase_url) # Establish connection with db server
    try:
        # creates a cursor for the session
        cur = conn.cursor()
        for meter in meters:
            upsert_meter(cur, meter)
        conn.commit()
        cur.close()
        return len(meters)
    except Exception:
        conn.rollback() # undoes everything in transaction
        raise
    finally:
        conn.close()