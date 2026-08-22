import argparse
import os
import sys

import psycopg2

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.keyvault import get_db_dsn

# Roles Supabase/Postgres create by default in every project. Never diffed
# or touched by this script -- only custom, application-created roles
# (e.g. app_user) are in scope.
BUILT_IN_ROLE_PREFIXES = ("pg_", "supabase_", "pgsodium")
BUILT_IN_ROLES = {
    "postgres",
    "anon",
    "authenticated",
    "service_role",
    "authenticator",
    "dashboard_user",
    "pgbouncer",
}


def is_custom_role(rolname):
    if rolname in BUILT_IN_ROLES:
        return False
    return not rolname.startswith(BUILT_IN_ROLE_PREFIXES)


def fetch_custom_roles(dsn):
    conn = psycopg2.connect(dsn)
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT rolname FROM pg_roles")
        return {row[0] for row in cursor.fetchall() if is_custom_role(row[0])}
    finally:
        conn.close()


def create_role(dsn, rolname):
    conn = psycopg2.connect(dsn)
    try:
        cursor = conn.cursor()
        cursor.execute(f'CREATE ROLE "{rolname}" NOLOGIN')
        conn.commit()
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser(
        description="Report (and optionally create) custom Postgres roles that exist in prod but not dev."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Create the missing roles in dev as NOLOGIN roles. Without this flag, only reports the diff.",
    )
    args = parser.parse_args()

    prod_roles = fetch_custom_roles(get_db_dsn("prod"))
    dev_roles = fetch_custom_roles(get_db_dsn("dev"))

    missing_in_dev = sorted(prod_roles - dev_roles)
    missing_in_prod = sorted(dev_roles - prod_roles)

    if not missing_in_dev and not missing_in_prod:
        print("No custom role drift between prod and dev.")
        return

    if missing_in_dev:
        print(f"Roles in prod but missing in dev: {', '.join(missing_in_dev)}")
    if missing_in_prod:
        print(f"Roles in dev but missing in prod: {', '.join(missing_in_prod)}")

    if not args.apply:
        print("Dry run only -- rerun with --apply to create the missing dev roles as NOLOGIN.")
        return

    dev_dsn = get_db_dsn("dev")
    for rolname in missing_in_dev:
        print(f"Creating role '{rolname}' in dev (NOLOGIN)...")
        create_role(dev_dsn, rolname)

    print("Done.")


if __name__ == "__main__":
    main()
