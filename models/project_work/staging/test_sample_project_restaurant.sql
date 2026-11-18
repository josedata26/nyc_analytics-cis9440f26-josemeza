 -- Quick test to verify source connection works
 SELECT
     camis,
     dba,
     boro,
     cuisine_description,
     inspection_date,
     critical_flag
 FROM {{ source('raw', 'nyc_restaurant_inspection_primary') }}
 LIMIT 10