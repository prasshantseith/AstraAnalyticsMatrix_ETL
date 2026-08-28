import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.email_utils import send_alert_email

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Ordered list of incremental pipelines this orchestrator runs, one at a time.
# To add a new pipeline (e.g. BSE Index), append another entry here once its
# ingestion script exists under src/ingestion/ and accepts --environment.
PIPELINES = [
    {"name": "MF Ingestion", "script": "src/ingestion/mf_ingest.py"},
    {"name": "NSE Bhavcopy", "script": "src/ingestion/nse_bhavcopy_ingest.py"},
    {"name": "BSE Bhavcopy", "script": "src/ingestion/bse_bhavcopy_ingest.py"},
    {"name": "NSE Index Daily Snapshot", "script": "src/ingestion/nse_index_daily_snapshot_ingest.py"},
]

ALERT_TO = "prasshantseith@gmail.com"
ALERT_CC = ["support@astraanalyticsmatrix.com"]


def run_pipeline(pipeline, environment):
    script_path = os.path.join(REPO_ROOT, pipeline["script"])
    start = datetime.now(timezone.utc)
    print(f"[{start.isoformat()}] START {pipeline['name']} (environment={environment})", flush=True)

    result = subprocess.run(
        [sys.executable, script_path, "--environment", environment],
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
    args = parser.parse_args()

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
