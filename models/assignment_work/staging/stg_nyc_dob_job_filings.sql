-- Clean and standardize NYC DOB job application data.
-- One row per DOB job application.

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_filing_number,
           filing_date,
           current_status_date, 
           first_permit_date, 
           approved_date,
           signoff_date,           
           job_type,
           job_description,
           building_type,                      
           borough,
           latitude,
           longitude          
       ),

       -- Identifiers
       CAST(job_filing_number AS STRING) AS job_filing_number,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(current_status_date AS TIMESTAMP) AS current_status_date,
       CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,
       CAST(signoff_date AS TIMESTAMP) AS signoff_date,

       -- Request details              
       CAST(job_type AS STRING) AS job_type,
       CAST(job_description AS STRING) AS job_description,
       CAST(building_type AS STRING) AS building_type,
       
       -- Location - clean zip code, handling several common zip code data problems
       -- all zip fields removed

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,
       
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,
       
   FROM source

   -- Filters
   WHERE (job_filing_number IS NOT NULL)
   AND filing_date IS NOT NULL   
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_filings

