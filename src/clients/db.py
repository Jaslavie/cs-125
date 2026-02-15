import os
from dotenv import load_dotenv
import psycopg2

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
        