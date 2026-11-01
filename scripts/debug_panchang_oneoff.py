import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from utils.keyvault import get_db_dsn

conn = psycopg2.connect(get_db_dsn("prod"), connect_timeout=15)
cur = conn.cursor()

cur.execute(
    """
    SELECT "Date","City","Time","Tithi","Paksha","Nakshatra_Name","Yoga_Name","Karana"
    FROM "Astro"."FactPanchang"
    WHERE "Date" IN ('2026-11-06','2026-11-07') AND "City" = 'Delhi'
    ORDER BY "Date","Time"
    """
)
print("--- FactPanchang rows ---")
for row in cur.fetchall():
    print(row)

cur.execute('SELECT id, yoga_name FROM "Astro"."DimYoga" ORDER BY id')
print("--- DimYoga ---")
for row in cur.fetchall():
    print(row)

cur.execute('SELECT id, karan_name FROM "Astro"."DimKarana" ORDER BY id')
print("--- DimKarana ---")
for row in cur.fetchall():
    print(row)

cur.execute('SELECT id, "number", paksha, swami FROM "Astro"."DimTithi" ORDER BY id')
print("--- DimTithi ---")
for row in cur.fetchall():
    print(row)

cur.execute('SELECT "NakshatraKey", "NakshatraName" FROM "Astro"."DimNakshtra" ORDER BY "NakshatraKey"')
print("--- DimNakshtra ---")
for row in cur.fetchall():
    print(row)

cur.close()
conn.close()
