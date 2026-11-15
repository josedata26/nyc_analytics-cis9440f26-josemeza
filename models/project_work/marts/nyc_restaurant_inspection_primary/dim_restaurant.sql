-- Restaurant dimension for restaurant inspections.
-- Grain: one row per restaurant (camis_id).

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