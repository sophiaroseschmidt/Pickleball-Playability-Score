{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_pickleball_courts') }}
),

cleaned AS (
    SELECT
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key([
            'court_name', 'city', 'state'
        ]) }} AS court_key,
        
        TRIM(court_name) AS court_name,
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        
        -- Validate coordinates
        CASE 
            WHEN latitude BETWEEN 25 AND 50 AND longitude BETWEEN -125 AND -65 
            THEN latitude 
            ELSE NULL 
        END AS latitude,
        
        CASE 
            WHEN latitude BETWEEN 25 AND 50 AND longitude BETWEEN -125 AND -65 
            THEN longitude 
            ELSE NULL 
        END AS longitude,
        
        COALESCE(num_courts, 1) AS num_courts,
        
        -- Standardize indoor/outdoor
        CASE 
            WHEN LOWER(indoor_outdoor) LIKE '%indoor%' AND LOWER(indoor_outdoor) LIKE '%outdoor%' THEN 'Both'
            WHEN LOWER(indoor_outdoor) LIKE '%indoor%' THEN 'Indoor'
            WHEN LOWER(indoor_outdoor) LIKE '%outdoor%' THEN 'Outdoor'
            ELSE 'Unknown'
        END AS facility_type,
        
        surface_type,
        COALESCE(lighting, FALSE) AS has_lighting,
        COALESCE(restrooms, FALSE) AS has_restrooms,
        COALESCE(parking, FALSE) AS has_parking,
        
        data_source,
        fetched_at AS loaded_at,
        CURRENT_TIMESTAMP AS transformed_at
        
    FROM source
)

SELECT * FROM cleaned