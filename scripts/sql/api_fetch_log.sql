CREATE TABLE bronze.api_fetch_log (
    id SERIAL PRIMARY KEY,
    fetch_date DATE,                  -- What day did we try to fetch?
    api_name VARCHAR(50),             -- Which API? 'weather_api', 'courts_api'
    status VARCHAR(20),               -- 'success', 'failed', 'partial'
    records_fetched INTEGER,          -- How many records did we get?
    error_message TEXT,               -- If it failed, what was the error?
    fetch_duration_seconds INTEGER,   -- How long did it take?
    fetched_at TIMESTAMP DEFAULT NOW() -- Exact time of the fetch
);