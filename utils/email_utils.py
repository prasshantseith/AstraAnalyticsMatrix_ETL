import smtplib
from email.mime.text import MIMEText

from utils.keyvault import get_secret_shared


def _load_smtp_config():
    """Fetches SMTP creds from Key Vault. Not per-environment (dev/prod) -
    alerting uses the same mailbox regardless of which target failed."""
    try:
        return {
            "host": get_secret_shared("SMTP-HOST"),
            "port": int(get_secret_shared("SMTP-PORT")),
            "user": get_secret_shared("SMTP-USER"),
            "password": get_secret_shared("SMTP-PASSWORD"),
            "from_email": get_secret_shared("SMTP-FROM-EMAIL"),
        }
    except Exception as exc:
        print(f"Could not load SMTP secrets from Key Vault ({exc}) - skipping email.")
        return None


def send_alert_email(subject, body, to_email, cc=None):
    """Send a plain-text alert email via SMTP, using creds from Key Vault.

    Mirrors the SMTP setup already used in AstraAnalyticsMatrixAPI
    (app/email_utils.py) so the same Gmail SMTP App Password can be reused.
    If SMTP isn't configured, logs the email instead of raising, so a
    missing secret doesn't fail the whole ingest run.
    """
    config = _load_smtp_config()
    if config is None:
        print(f"Skipping email to {to_email}. Body follows:\n{body}")
        return

    smtp_host = config["host"]
    smtp_port = config["port"]
    smtp_user = config["user"]
    smtp_password = config["password"]
    smtp_from_email = config["from_email"] or smtp_user

    message = MIMEText(body)
    message["Subject"] = subject
    message["From"] = smtp_from_email
    message["To"] = to_email
    if cc:
        message["Cc"] = ", ".join(cc)

    recipients = [to_email, *(cc or [])]
    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.sendmail(smtp_from_email, recipients, message.as_string())
