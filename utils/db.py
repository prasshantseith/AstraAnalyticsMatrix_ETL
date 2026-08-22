from psycopg2.extras import execute_values

# Kept comfortably below Postgres's 65535-parameter limit for any
# reasonable column count, while still summing an accurate row count --
# execute_values' own default page_size=100 silently caps cursor.rowcount
# at just the last page's count for larger batches.
DEFAULT_PAGE_SIZE = 1000


def execute_values_counted(cursor, sql_query, values, page_size=DEFAULT_PAGE_SIZE):
    total = 0

    for start in range(0, len(values), page_size):
        chunk = values[start:start + page_size]
        execute_values(cursor, sql_query, chunk, page_size=len(chunk))
        total += cursor.rowcount

    return total
