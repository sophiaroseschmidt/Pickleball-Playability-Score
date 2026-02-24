-- Gold: Today's best cities for pickleball (for email)
{{ config(materialized='view') }}

SELECT
    city,
    state,
    forecast_date,
    playability_score,
    playability_reason,
    temperature_f,
    weather_condition_clean,
    wind_speed_mph,
    total_courts,
    
    -- Rank cities
    ROW_NUMBER() OVER (
        PARTITION BY forecast_date 
        ORDER BY playability_score DESC
    ) AS rank
    
FROM {{ ref('daily_city_playability') }}
WHERE forecast_date = CURRENT_DATE

-- Only show top 10 cities
QUALIFY rank <= 10
ORDER BY playability_score DESC