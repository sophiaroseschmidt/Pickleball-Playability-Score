-- Silver: Cleaned weather data
{{ config(materialized='incremental', unique_key='weather_key') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_weather_data') }}
    {% if is_incremental() %}
    WHERE fetched_at > (SELECT MAX(loaded_at) FROM {{ this }})
    {% endif %}
),

cleaned AS (
    SELECT
        -- Generate surrogate key
        {{ dbt_utils.generate_surrogate_key([
            'city', 'state', 'forecast_date'
        ]) }} AS weather_key,
        
        -- Standardize city names (Phoenix vs PHOENIX vs phoenix)
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        
        -- Clean numeric fields
        ROUND(temperature_f, 1) AS temperature_f,
        
        -- Handle nulls and outliers
        COALESCE(humidity_pct, 50) AS humidity_pct,  -- Default to 50% if missing
        CASE 
            WHEN wind_speed_mph < 0 THEN 0
            WHEN wind_speed_mph > 100 THEN NULL  -- Likely data error
            ELSE ROUND(wind_speed_mph, 1)
        END AS wind_speed_mph,
        
        -- Standardize weather conditions
        CASE 
            WHEN LOWER(weather_condition) IN ('rain', 'drizzle', 'shower') THEN 'Rain'
            WHEN LOWER(weather_condition) IN ('clear', 'sunny') THEN 'Clear'
            WHEN LOWER(weather_condition) IN ('clouds', 'cloudy', 'overcast') THEN 'Cloudy'
            WHEN LOWER(weather_condition) IN ('snow', 'sleet') THEN 'Snow'
            ELSE 'Other'
        END AS weather_condition_clean,
        
        precipitation_in,
        forecast_date,
        data_source,
        fetched_at AS loaded_at,
        CURRENT_TIMESTAMP AS transformed_at
        
    FROM source
    
    -- Data quality filters
    WHERE forecast_date IS NOT NULL
      AND temperature_f BETWEEN -50 AND 150  -- Reasonable temp range
      AND city IS NOT NULL
)

SELECT * FROM cleaned