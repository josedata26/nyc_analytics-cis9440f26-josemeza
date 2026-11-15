-- Restaurant dimension for restaurant inspections.
-- Grain: one row per restaurant (camis_id).
-- We added a qualifier that will keep just the latest version of each restaurant, as the camis doesnt change, but the name or address can.

WITH stg_restaurant AS (
    SELECT * FROM {{ ref('staging_restaurant_primary') }}
),

distinct_restaurant AS (
    SELECT DISTINCT
        camis AS camis_id,
        dba AS dba_name,
        building,
        street,                           
        bin                                      
    FROM stg_restaurant
    WHERE camis IS NOT NULL   
    QUALIFY ROW_NUMBER() OVER (PARTITION BY camis ORDER BY inspection_date DESC) = 1 
),

dim_restaurant AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['camis_id']) }} AS restaurant_key,
        camis_id,
        dba_name,
        building,
        street,
        bin
    FROM distinct_restaurant
)

SELECT * FROM dim_restaurant