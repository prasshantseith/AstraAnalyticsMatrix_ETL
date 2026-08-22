import os
from urllib.parse import quote
from azure.identity import ClientSecretCredential
from azure.keyvault.secrets import SecretClient

VAULT_URL = "https://kv-astra-anlytics-matrix.vault.azure.net/"


def _get_client() -> SecretClient:
    credential = ClientSecretCredential(
        tenant_id=os.environ["AZURE_TENANT_ID"],
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_secret=os.environ["AZURE_CLIENT_SECRET"],
    )
    return SecretClient(vault_url=VAULT_URL, credential=credential)


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
    host = get_secret("SUPABASE-POSTGRE-HOST", environment)
    db   = get_secret("SUPABASE-POSTGRE-DB", environment)
    user = get_secret("SUPABASE-POSTGRE-USER", environment)
    pwd  = get_secret("SUPABASE-POSTGRE-PASSWORD", environment)
    port = os.environ.get("SUPABASE_POSTGRE_PORT", "6543")

    return f"postgresql://{quote(user, safe='')}:{quote(pwd, safe='')}@{host}:{port}/{db}"
