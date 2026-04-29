import os
import pyodbc
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    server   = os.getenv('SQL_SERVER')
    database = os.getenv('SQL_DATABASE')
    username = os.getenv('SQL_USER')
    password = os.getenv('SQL_PASSWORD')

    conn_str = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server},1433;"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )
    
    return pyodbc.connect(conn_str)
