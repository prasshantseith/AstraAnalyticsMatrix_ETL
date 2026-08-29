import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from utils.keyvault import get_secret_shared

# Port 465 is implicit TLS from the first byte (needs SMTP_SSL); port 587
# (and anything else) is plaintext-then-upgrade (needs SMTP + starttls()).
# Using the wrong one for a given port hangs until the peer resets the
# connection, rather than failing cleanly.
SSL_PORT = 465


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


def send_alert_email(subject, body, to_email, cc=None, html_body=None):
    """Send an alert email via SMTP, using creds from Key Vault.

    body is always sent as the plain-text fallback. Pass html_body to also
    send a multipart/alternative HTML version - most clients render that
    instead of the plain-text part, but the fallback keeps it readable in
    clients that don't render HTML.

    Same idea as the SMTP setup in AstraAnalyticsMatrixAPI (app/email_utils.py),
    reusing the mailbox already configured there. If SMTP isn't configured,
    logs the email instead of raising, so a missing secret doesn't fail the
    whole ingest run.
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

    if html_body:
        message = MIMEMultipart("alternative")
        message.attach(MIMEText(body, "plain"))
        message.attach(MIMEText(html_body, "html"))
    else:
        message = MIMEText(body, "plain")

    message["Subject"] = subject
    message["From"] = smtp_from_email
    message["To"] = to_email
    if cc:
        message["Cc"] = ", ".join(cc)

    recipients = [to_email, *(cc or [])]
    if smtp_port == SSL_PORT:
        with smtplib.SMTP_SSL(smtp_host, smtp_port, context=ssl.create_default_context()) as server:
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_from_email, recipients, message.as_string())
    else:
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_from_email, recipients, message.as_string())
