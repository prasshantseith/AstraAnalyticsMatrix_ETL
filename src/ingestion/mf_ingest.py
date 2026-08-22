import requests
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values
from datetime import datetime
import os
import json

JOB_NAME = "mf_nav_ingest"

# -----------------------------
# 1. Fetch Azure Key Vault Secret
# -----------------------------
def get_kv_secret(secret_name):
    tenant_id = os.getenv("AZURE_TENANT_ID")
    client_id = os.getenv("AZURE_CLIENT_ID")
    client_secret = os.getenv("AZURE_CLIENT_SECRET")
    keyvault_name = os.getenv("KEYVAULT_NAME")

    # Step 1: Get Azure Access Token
    token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
    token_payload = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "resource": "https://vault.azure.net"
    }

    token_response = requests.post(token_url, data=token_payload)
    token_json = token_response.json()

    if "access_token" not in token_json:
        raise Exception(f"Failed to get Azure token: {token_json}")

    access_token = token_json["access_token"]

    # Step 2: Fetch secret from Key Vault
    secret_url = f"https://{keyvault_name}.vault.azure.net/secrets/{secret_name}?api-version=7.3"
    headers = {"Authorization": f"Bearer {access_token}"}

    secret_response = requests.get(secret_url, headers=headers)
    secret_json = secret_response.json()

    return secret_json.get("value")


# -----------------------------
# 2. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres():
    host = get_kv_secret("SUPABASE-POSTGRE-HOST")
    database = get_kv_secret("SUPABASE-POSTGRE-DB")
    user = get_kv_secret("SUPABASE-POSTGRE-USER")
    password = get_kv_secret("SUPABASE-POSTGRE-PASSWORD")
    port = os.getenv("SUPABASE_POSTGRE_PORT", "6543")

    return psycopg2.connect(
        host=host,
        port=port,
        database=database,
        user=user,
        password=password,
        sslmode="require"
    )


# -----------------------------
# 3. Load Job Config
# -----------------------------
def get_job_config(cursor, job_name):
    cursor.execute(
        """
        SELECT source_url, target_schema, target_table, enabled
        FROM "ETL"."ETL_CONFIG"
        WHERE job_name = %s
        """,
        (job_name,)
    )
    row = cursor.fetchone()

    if row is None:
        raise Exception(f"No config found in ETL.ETL_CONFIG for job '{job_name}'")

    return {
        "source_url": row[0],
        "target_schema": row[1],
        "target_table": row[2],
        "enabled": row[3],
    }


def set_job_status(cursor, job_name, status):
    cursor.execute(
        """
        UPDATE "ETL"."ETL_CONFIG"
        SET last_run_at = now(), last_run_status = %s, updated_at = now()
        WHERE job_name = %s
        """,
        (status, job_name)
    )


# -----------------------------
# 4. Fetch MFAPI Data
# -----------------------------
def fetch_mf_latest(source_url):
    response = requests.get(source_url, timeout=30)

    if response.status_code != 200:
        raise Exception(f"MFAPI failed: {response.status_code}")

    return response.json()


# -----------------------------
# 5. Transform MFAPI Rows
# -----------------------------
def transform_rows(data):
    rows = []

    for item in data:
        scheme_code = item.get("schemeCode")
        scheme_name = item.get("schemeName")
        nav = item.get("nav")
        nav_date = item.get("date")

        if nav is None or nav_date is None:
            continue

        try:
            nav_date_pg = datetime.strptime(nav_date, "%d-%m-%Y").date()
        except ValueError:
            continue

        try:
            nav_numeric = float(nav)
        except (TypeError, ValueError):
            continue

        nav_date_key = int(nav_date_pg.strftime("%Y%m%d"))

        rows.append((
            scheme_code,
            scheme_name,
            nav_date_pg,
            nav_numeric,
            nav_date_key
        ))

    return rows


# -----------------------------
# 6. Insert into Supabase PostgreSQL
# -----------------------------
def insert_into_postgres(cursor, target_schema, target_table, rows):
    insert_sql = sql.SQL(
        """
        INSERT INTO {}.{}
        ("SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey")
        VALUES %s
        ON CONFLICT ("SchemeCode", "NavDate") DO NOTHING;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    execute_values(cursor, insert_sql, rows)


# -----------------------------
# 7. Main
# -----------------------------
def main():
    conn = connect_to_postgres()
    cursor = conn.cursor()

    try:
        config = get_job_config(cursor, JOB_NAME)

        if not config["enabled"]:
            print(f"Job '{JOB_NAME}' is disabled in ETL.ETL_CONFIG, skipping.")
            set_job_status(cursor, JOB_NAME, "skipped")
            conn.commit()
            return

        print("Fetching MFAPI latest NAV data...")
        data = fetch_mf_latest(config["source_url"])

        print(f"Records received: {len(data)}")

        rows = transform_rows(data)

        print(f"Rows prepared for insert: {len(rows)}")

        insert_into_postgres(cursor, config["target_schema"], config["target_table"], rows)

        set_job_status(cursor, JOB_NAME, "success")
        conn.commit()

        print("Insert completed.")
    except Exception:
        conn.rollback()
        set_job_status(cursor, JOB_NAME, "failed")
        conn.commit()
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()
