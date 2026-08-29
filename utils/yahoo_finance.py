import json
import urllib.request
from datetime import datetime, timedelta, timezone

CHART_URL = "https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}


def fetch_ohlc(symbol, start_date=None, end_date=None, timeout=30):
    """Fetch daily OHLC candles for a Yahoo Finance symbol (e.g. 'GC=F').

    Omit start_date/end_date for the full available history - Yahoo just
    clamps to whatever it actually has, so one call covers both a fresh
    backfill and a narrow incremental range. Rows with no close price
    (the still-open current session, or a data gap) are skipped.
    """
    period1 = 0
    if start_date:
        period1 = int(datetime.combine(start_date, datetime.min.time(), tzinfo=timezone.utc).timestamp())
    period2 = 9999999999
    if end_date:
        period2 = int(datetime.combine(end_date + timedelta(days=1), datetime.min.time(), tzinfo=timezone.utc).timestamp())

    url = f"{CHART_URL.format(symbol=symbol)}?period1={period1}&period2={period2}&interval=1d"
    request = urllib.request.Request(url, headers=REQUEST_HEADERS)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.load(response)

    result = payload["chart"]["result"]
    if not result:
        return []

    chart = result[0]
    timestamps = chart.get("timestamp") or []
    quote = chart["indicators"]["quote"][0]

    rows = []
    for i, ts in enumerate(timestamps):
        close = quote["close"][i]
        if close is None:
            continue
        rows.append(
            {
                "trade_date": datetime.fromtimestamp(ts, tz=timezone.utc).date(),
                "open": quote["open"][i],
                "high": quote["high"][i],
                "low": quote["low"][i],
                "close": close,
                "volume": quote["volume"][i],
            }
        )
    return rows
