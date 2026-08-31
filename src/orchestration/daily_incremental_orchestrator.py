import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.email_utils import send_alert_email

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# For the email table's Start/End columns - IST since the data is India's,
# NZ since that's the reader's local time. NZ observes DST (NZST/NZDT),
# which is why this uses zoneinfo rather than a fixed offset (IST has no
# DST, but ZoneInfo handles it identically either way).
IST_TZ = ZoneInfo("Asia/Kolkata")
NZ_TZ = ZoneInfo("Pacific/Auckland")


def format_time_cell_html(dt):
    """Stacked UTC/IST/NZ lines for one table cell - three timezones side
    by side on one line would make the column too wide in a 640px email."""
    utc_str = dt.strftime("%H:%M:%S")
    ist_str = dt.astimezone(IST_TZ).strftime("%H:%M:%S %Z")
    nz_str = dt.astimezone(NZ_TZ).strftime("%H:%M:%S %Z")
    return (
        f'<div>{utc_str} UTC</div>'
        f'<div style="color:#8b949e;font-size:11px;margin-top:2px;">{ist_str}</div>'
        f'<div style="color:#8b949e;font-size:11px;margin-top:1px;">{nz_str}</div>'
    )

# Ordered list of incremental pipelines this orchestrator runs, one at a time.
# To add a new pipeline, append another entry here once its ingestion
# script exists under src/ingestion/ and accepts --environment. "extra_args"
# is optional, for scripts that need more than just --environment (e.g.
# call_procedure.py, which is generic and needs --job-name/--procedure
# to say which one).
#
# The three refresh procedures at the end must run after all ingestion
# (they recompute derived data) and Refresh Date Flags must run before
# the two performance refreshes (both filter on Report.dimDate's
# IsCurrent* flags, which only Refresh Date Flags sets for "today").
#
# All three use the session pooler (5432), not the default transaction
# pooler (6543) - same root cause as the migrations fix in
# apply_migrations.yml (82f03c8): these run heavy analytical queries that
# can take well over a minute as the underlying tables grow, and the
# transaction pooler enforces a short statement_timeout meant for quick
# pooled queries (observed: Refresh Stock Performance killed by
# "canceling statement due to statement timeout" at 126s).
REFRESH_PROC_ENV = {"SUPABASE_POSTGRE_PORT": "5432"}

PIPELINES = [
    {"name": "MF Ingestion", "script": "src/ingestion/mf_ingest.py"},
    {"name": "NSE Bhavcopy", "script": "src/ingestion/nse_bhavcopy_ingest.py"},
    {"name": "BSE Bhavcopy", "script": "src/ingestion/bse_bhavcopy_ingest.py"},
    {"name": "NSE Index Daily Snapshot", "script": "src/ingestion/nse_index_daily_snapshot_ingest.py"},
    {"name": "BSE Index", "script": "src/ingestion/bse_index_ingest.py"},
    {"name": "Commodity Data (Gold/Silver/Copper + 12 more)", "script": "src/ingestion/commodity_data_ingest.py"},
    {
        "name": "Refresh Date Flags",
        "script": "src/orchestration/call_procedure.py",
        "extra_args": ["--job-name", "refresh_dim_date_flags", "--procedure", "Report.usp_RefreshDimDateFlags"],
        "extra_env": REFRESH_PROC_ENV,
    },
    {
        "name": "Refresh MF Performance",
        "script": "src/orchestration/call_procedure.py",
        "extra_args": ["--job-name", "refresh_mf_performance", "--procedure", "MF.usp_RefreshMFPerformance"],
        "extra_env": REFRESH_PROC_ENV,
    },
    {
        "name": "Refresh Stock Performance",
        "script": "src/orchestration/call_procedure.py",
        "extra_args": ["--job-name", "refresh_stock_performance", "--procedure", "Stocks.usp_RefreshStockPerformance"],
        "extra_env": REFRESH_PROC_ENV,
    },
]

ALERT_TO = "prasshantseith@gmail.com"
ALERT_CC = ["support@astraanalyticsmatrix.com"]


def run_pipeline(pipeline, environment):
    script_path = os.path.join(REPO_ROOT, pipeline["script"])
    extra_args = pipeline.get("extra_args", [])
    env = {**os.environ, **pipeline.get("extra_env", {})}
    start = datetime.now(timezone.utc)
    print(f"[{start.isoformat()}] START {pipeline['name']} (environment={environment})", flush=True)

    result = subprocess.run(
        [sys.executable, script_path, "--environment", environment, *extra_args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        env=env,
    )

    end = datetime.now(timezone.utc)
    duration = (end - start).total_seconds()
    status = "success" if result.returncode == 0 else "failed"

    print(f"[{end.isoformat()}] DONE  {pipeline['name']} status={status} duration={duration:.1f}s", flush=True)
    if result.stdout:
        print(result.stdout, flush=True)
    if status == "failed" and result.stderr:
        print(result.stderr, flush=True)

    return {
        "name": pipeline["name"],
        "start": start,
        "end": end,
        "duration": duration,
        "status": status,
        # Keep the email body bounded even if a traceback is huge.
        "error": result.stderr.strip()[-4000:] if status == "failed" else None,
    }


def build_summary(results):
    return "\n".join(
        f"{r['name']}: {r['status'].upper()} "
        f"(start={r['start'].isoformat()}, end={r['end'].isoformat()}, duration={r['duration']:.1f}s)"
        for r in results
    )


def build_email_body(results, environment):
    failed = [r for r in results if r["status"] == "failed"]
    body = f"Incremental ingest run for environment={environment}\n\nSummary:\n{build_summary(results)}\n\n"
    if failed:
        body += "Failure details:\n\n"
        for r in failed:
            body += f"--- {r['name']} ---\n{r['error']}\n\n"
    return body


def _escape_html(text):
    return (
        (text or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


# (background, text) colors per status - kept as plain hex pairs rather than
# a hex+alpha shorthand, since 8-digit hex alpha isn't reliably supported
# across email clients (notably Outlook).
STATUS_COLORS = {
    "success": ("#dafbe1", "#1a7f37"),
    "failed": ("#ffebe9", "#cf222e"),
}


def build_email_html(results, environment):
    failed = [r for r in results if r["status"] == "failed"]
    run_date = datetime.now(timezone.utc).date().isoformat()

    rows_html = ""
    for r in results:
        bg, fg = STATUS_COLORS.get(r["status"], ("#f6f8fa", "#57606a"))
        rows_html += f"""
        <tr>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-family:Arial,sans-serif;font-size:14px;color:#1f2328;">{_escape_html(r['name'])}</td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;text-align:center;">
            <span style="display:inline-block;padding:3px 10px;border-radius:12px;background:{bg};color:{fg};font-family:Arial,sans-serif;font-size:12px;font-weight:bold;">{r['status'].upper()}</span>
          </td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-family:Arial,sans-serif;font-size:13px;color:#57606a;white-space:nowrap;">{format_time_cell_html(r['start'])}</td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-family:Arial,sans-serif;font-size:13px;color:#57606a;white-space:nowrap;">{format_time_cell_html(r['end'])}</td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-family:Arial,sans-serif;font-size:13px;color:#57606a;text-align:right;white-space:nowrap;">{r['duration']:.1f}s</td>
        </tr>
        """

    failure_html = ""
    if failed:
        blocks = "".join(
            f"""
            <div style="margin-bottom:16px;border:1px solid #ffcecb;border-radius:6px;overflow:hidden;">
              <div style="background:#ffebe9;padding:8px 14px;font-family:Arial,sans-serif;font-size:13px;font-weight:bold;color:#cf222e;">{_escape_html(r['name'])}</div>
              <pre style="margin:0;padding:12px 14px;font-family:Consolas,Monaco,monospace;font-size:12px;line-height:1.5;color:#1f2328;background:#f6f8fa;white-space:pre-wrap;word-break:break-word;">{_escape_html(r['error'])}</pre>
            </div>
            """
            for r in failed
        )
        failure_html = f"""
        <h3 style="font-family:Arial,sans-serif;font-size:15px;color:#cf222e;margin:24px 0 12px 0;">Failure Details</h3>
        {blocks}
        """

    status_label = "All Steps Succeeded" if not failed else f"{len(failed)} of {len(results)} Steps Failed"
    status_bg, status_fg = STATUS_COLORS["success"] if not failed else STATUS_COLORS["failed"]

    return f"""\
<html>
<body style="margin:0;padding:0;background:#f6f8fa;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f6f8fa;padding:24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="640" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:8px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#1f2937;padding:20px 24px;">
              <div style="font-family:Arial,sans-serif;font-size:16px;color:#ffffff;font-weight:bold;">AstraAnalyticsMatrix ETL</div>
              <div style="font-family:Arial,sans-serif;font-size:13px;color:#9ca3af;margin-top:2px;">Daily Incremental Ingest &mdash; {run_date} &mdash; environment={environment}</div>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px 0 24px;">
              <span style="display:inline-block;padding:4px 12px;border-radius:12px;background:{status_bg};color:{status_fg};font-family:Arial,sans-serif;font-size:13px;font-weight:bold;">{status_label}</span>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px 24px 24px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:1px solid #e5e7eb;border-radius:6px;">
                <tr style="background:#f6f8fa;">
                  <th align="left" style="padding:10px 14px;font-family:Arial,sans-serif;font-size:11px;color:#57606a;text-transform:uppercase;letter-spacing:0.03em;">Step</th>
                  <th align="center" style="padding:10px 14px;font-family:Arial,sans-serif;font-size:11px;color:#57606a;text-transform:uppercase;letter-spacing:0.03em;">Status</th>
                  <th align="left" style="padding:10px 14px;font-family:Arial,sans-serif;font-size:11px;color:#57606a;text-transform:uppercase;letter-spacing:0.03em;">Start</th>
                  <th align="left" style="padding:10px 14px;font-family:Arial,sans-serif;font-size:11px;color:#57606a;text-transform:uppercase;letter-spacing:0.03em;">End</th>
                  <th align="right" style="padding:10px 14px;font-family:Arial,sans-serif;font-size:11px;color:#57606a;text-transform:uppercase;letter-spacing:0.03em;">Duration</th>
                </tr>
                {rows_html}
              </table>
              {failure_html}
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px;background:#f6f8fa;border-top:1px solid #e5e7eb;">
              <div style="font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;">Sent automatically by daily_incremental_orchestrator.py</div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default="prod", help="dev or prod (default: prod)")
    parser.add_argument(
        "--test-email",
        action="store_true",
        help="Skip all pipelines and just send a test alert email, to verify "
             "the Key Vault SMTP config end to end.",
    )
    args = parser.parse_args()

    if args.test_email:
        # Sample results exercising the real HTML table (success + a
        # failure, so the failure-details block renders too), rather than
        # actually running any pipeline - just to verify the email path
        # and formatting end to end.
        now = datetime.now(timezone.utc)
        sample_results = [
            {"name": p["name"], "start": now, "end": now, "duration": 12.3, "status": "success", "error": None}
            for p in PIPELINES[:-1]
        ] + [
            {
                "name": PIPELINES[-1]["name"],
                "start": now,
                "end": now,
                "duration": 4.1,
                "status": "failed",
                "error": "Sample error - this is a test email, not a real failure.",
            }
        ]
        send_alert_email(
            "[AstraAnalyticsMatrix ETL] Test email from daily_incremental_orchestrator",
            build_email_body(sample_results, args.environment),
            ALERT_TO,
            cc=ALERT_CC,
            html_body=build_email_html(sample_results, args.environment),
        )
        print(f"Test email sent to {ALERT_TO} (cc {', '.join(ALERT_CC)})", flush=True)
        return

    # Run every pipeline in order, regardless of earlier failures.
    results = [run_pipeline(pipeline, args.environment) for pipeline in PIPELINES]

    failed = [r for r in results if r["status"] == "failed"]
    run_date = datetime.now(timezone.utc).date().isoformat()
    if failed:
        subject = (
            f"[AstraAnalyticsMatrix ETL] Incremental ingest FAILURES "
            f"({len(failed)}/{len(results)}) - {run_date}"
        )
    else:
        subject = (
            f"[AstraAnalyticsMatrix ETL] Incremental ingest SUCCESS "
            f"({len(results)}/{len(results)}) - {run_date}"
        )
    # Always sent now (was failure-only) - one consolidated summary per run,
    # covering every step, success or not.
    send_alert_email(
        subject,
        build_email_body(results, args.environment),
        ALERT_TO,
        cc=ALERT_CC,
        html_body=build_email_html(results, args.environment),
    )
    print(f"Sent summary email to {ALERT_TO} (cc {', '.join(ALERT_CC)})", flush=True)

    print("\n=== Final summary ===")
    print(build_summary(results))

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
