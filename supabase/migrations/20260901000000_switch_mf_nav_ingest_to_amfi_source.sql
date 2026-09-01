-- mf_ingest.py now parses AMFI's daily NAVAll.txt (same source already used
-- by mf_metadata_sync) instead of calling api.mfapi.in/mf/latest, which was
-- failing intermittently with read timeouts under load.
update "ETL"."ETL_CONFIG"
set source_url = 'https://portal.amfiindia.com/spages/NAVAll.txt',
    updated_at = now()
where job_name = 'mf_nav_ingest';
