import os
from urllib.parse import quote
from azure.identity import ClientSecretCredential
from azure.keyvault.secrets import SecretClient

VAULT_URL = "https://kv-astra-anlytics-matrix.vault.azure.net/"

# Bound how long a Key Vault call can hang - a long-running ingest job that
# reconnects on every failure calls this repeatedly, and an unbounded Azure
# SDK call (no timeout by default) can freeze the whole job the same way an
# unbounded psycopg2.connect() did.
CONNECTION_TIMEOUT = 10
READ_TIMEOUT = 15


def _get_client() -> SecretClient:
    credential = ClientSecretCredential(
        tenant_id=os.environ["AZURE_TENANT_ID"],
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_secret=os.environ["AZURE_CLIENT_SECRET"],
        connection_timeout=CONNECTION_TIMEOUT,
        read_timeout=READ_TIMEOUT,
    )
    return SecretClient(
        vault_url=VAULT_URL,
        credential=credential,
        connection_timeout=CONNECTION_TIMEOUT,
        read_timeout=READ_TIMEOUT,
    )


def get_secret(base_name: str, environment: str = None) -> str:
    """
    base_name: e.g. 'SUPABASE-POSTGRE-PASSWORD'
    environment: 'dev' or 'prod' — defaults to the ENVIRONMENT env var
    Resolves to '<base_name>-DEV' for dev, '<base_name>' (unsuffixed) for prod.
    """
    environment = (environment or os.environ.get("ENVIRONMENT", "prod")).lower()
    suffix = "-DEV" if environment == "dev" else ""
    secret_name = f"{base_name}{suffix}"

    client = _get_client()
    return client.get_secret(secret_name).value


def get_db_dsn(environment: str = None) -> str:
    """Builds a full Postgres DSN from the four separate KV secrets."""
    client = _get_client()  # one authenticated client, reused for all four
    environment = (environment or os.environ.get("ENVIRONMENT", "prod")).lower()
    suffix = "-DEV" if environment == "dev" else ""

    def fetch(base_name):
        return client.get_secret(f"{base_name}{suffix}").value

    host = fetch("SUPABASE-POSTGRE-HOST")
    db   = fetch("SUPABASE-POSTGRE-DB")
    user = fetch("SUPABASE-POSTGRE-USER")
    pwd  = fetch("SUPABASE-POSTGRE-PASSWORD")
    port = os.environ.get("SUPABASE_POSTGRE_PORT", "6543")

    return f"postgresql://{quote(user, safe='')}:{quote(pwd, safe='')}@{host}:{port}/{db}"
