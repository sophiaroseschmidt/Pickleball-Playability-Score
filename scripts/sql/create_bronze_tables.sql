-- Connect to your database first, where the heck is this database
\c pickleball_db;

-- Bronze: Raw weather data from API
CREATE TABLE bronze.raw_weather_data (
    id SERIAL PRIMARY KEY,
    city VARCHAR(255),
    state VARCHAR(2),
    api_response JSONB,           -- Store entire API response as JSON
    temperature_f DECIMAL(5,2),   -- Also extract key fields for convenience
    humidity_pct INTEGER,
    wind_speed_mph DECIMAL(5,2),
    precipitation_in DECIMAL(5,2),
    weather_condition VARCHAR(100),
    forecast_date DATE,
    fetched_at TIMESTAMP DEFAULT NOW(),
    data_source VARCHAR(50)       -- Which API? 'openweather', 'weatherapi', etc.
);

-- Bronze: Raw pickleball court data
CREATE TABLE bronze.raw_pickleball_courts (
    id SERIAL PRIMARY KEY,
    api_response JSONB,           -- Full API response
    court_name VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(2),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    num_courts INTEGER,
    indoor_outdoor VARCHAR(20),   -- 'indoor', 'outdoor', 'both'
    surface_type VARCHAR(50),     -- 'asphalt', 'concrete', 'sport court'
    lighting BOOLEAN,
    restrooms BOOLEAN,
    parking BOOLEAN,
    data_source VARCHAR(50),
    fetched_at TIMESTAMP DEFAULT NOW()
);

-- Bronze: Daily API fetch log (data quality tracking)
CREATE TABLE bronze.api_fetch_log (
    id SERIAL PRIMARY KEY,
    fetch_date DATE,
    api_name VARCHAR(50),         -- 'weather_api', 'courts_api'
    status VARCHAR(20),            -- 'success', 'failed', 'partial'
    records_fetched INTEGER,
    error_message TEXT,
    fetch_duration_seconds INTEGER,
    fetched_at TIMESTAMP DEFAULT NOW()
);