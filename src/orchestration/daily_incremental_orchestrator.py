import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.email_utils import send_alert_email

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

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
    },
    {
        "name": "Refresh MF Performance",
        "script": "src/orchestration/call_procedure.py",
        "extra_args": ["--job-name", "refresh_mf_performance", "--procedure", "MF.usp_RefreshMFPerformance"],
    },
    {
        "name": "Refresh Stock Performance",
        "script": "src/orchestration/call_procedure.py",
        "extra_args": ["--job-name", "refresh_stock_performance", "--procedure", "Stocks.usp_RefreshStockPerformance"],
    },
]

ALERT_TO = "prasshantseith@gmail.com"
ALERT_CC = ["support@astraanalyticsmatrix.com"]


def run_pipeline(pipeline, environment):
    script_path = os.path.join(REPO_ROOT, pipeline["script"])
    extra_args = pipeline.get("extra_args", [])
    start = datetime.now(timezone.utc)
    print(f"[{start.isoformat()}] START {pipeline['name']} (environment={environment})", flush=True)

    result = subprocess.run(
        [sys.executable, script_path, "--environment", environment, *extra_args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
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
        run_time = datetime.now(timezone.utc).isoformat()
        send_alert_email(
            "[AstraAnalyticsMatrix ETL] Test email from daily_incremental_orchestrator",
            f"This is a test of the orchestrator's alert email path.\n\n"
            f"Sent at: {run_time}\n"
            f"If you received this, Key Vault SMTP config is working correctly.",
            ALERT_TO,
            cc=ALERT_CC,
        )
        print(f"Test email sent to {ALERT_TO} (cc {', '.join(ALERT_CC)})", flush=True)
        return

    # Run every pipeline in order, regardless of earlier failures.
    results = [run_pipeline(pipeline, args.environment) for pipeline in PIPELINES]

    failed = [r for r in results if r["status"] == "failed"]
    if failed:
        run_date = datetime.now(timezone.utc).date().isoformat()
        subject = (
            f"[AstraAnalyticsMatrix ETL] Incremental ingest FAILURES "
            f"({len(failed)}/{len(results)}) - {run_date}"
        )
        send_alert_email(subject, build_email_body(results, args.environment), ALERT_TO, cc=ALERT_CC)
        print(f"Sent failure alert email to {ALERT_TO} (cc {', '.join(ALERT_CC)})", flush=True)

    print("\n=== Final summary ===")
    print(build_summary(results))

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
