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


def log_run_start(cursor, job_name, start_time):
    cursor.execute(
        """
        INSERT INTO "ETL"."ETL_LOG" (job_name, start_time, status)
        VALUES (%s, %s, 'running')
        RETURNING log_id
        """,
        (job_name, start_time)
    )
    return cursor.fetchone()[0]


def log_run_end(cursor, log_id, status, rows_updated=None, watermark_value=None, error_message=None):
    cursor.execute(
        """
        UPDATE "ETL"."ETL_LOG"
        SET end_time = now(),
            status = %s,
            rows_updated = %s,
            watermark_value = %s,
            error_message = %s
        WHERE log_id = %s
        """,
        (status, rows_updated, watermark_value, error_message, log_id)
    )
