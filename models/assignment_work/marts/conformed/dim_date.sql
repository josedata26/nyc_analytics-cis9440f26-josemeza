-- Date dimension shared by DOT 311 service requests and DOB NOW job filings
-- Grain: one row per calendar date

WITH stg_311 AS (
    SELECT * FROM {{ ref('stg_nyc_311_dot') }}
),

stg_dob AS (
    SELECT * FROM {{ ref('stg_nyc_dob_job_filings') }}
),

all_dates AS (
    SELECT DATE(created_date)         AS full_date FROM stg_311 WHERE created_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(closed_date)          FROM stg_311 WHERE closed_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(filing_date)          FROM stg_dob WHERE filing_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(current_status_date)  FROM stg_dob WHERE current_status_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(first_permit_date)    FROM stg_dob WHERE first_permit_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(approved_date)        FROM stg_dob WHERE approved_date IS NOT NULL
    UNION DISTINCT
    SELECT DATE(signoff_date)         FROM stg_dob WHERE signoff_date IS NOT NULL
),

-- NYC fiscal year runs Jul 1 - Jun 30
date_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,
        full_date,
        EXTRACT(YEAR FROM full_date)       AS year,
        EXTRACT(QUARTER FROM full_date)    AS quarter,
        EXTRACT(MONTH FROM full_date)      AS month,
        FORMAT_DATE('%B', full_date)       AS month_name,
        EXTRACT(DAY FROM full_date)        AS day_of_month,
        EXTRACT(DAYOFWEEK FROM full_date)  AS day_of_week,
        FORMAT_DATE('%A', full_date)       AS weekday_name,
        EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) AS is_weekend,
        CASE
            WHEN EXTRACT(MONTH FROM full_date) >= 7 THEN EXTRACT(YEAR FROM full_date) + 1
            ELSE EXTRACT(YEAR FROM full_date)
        END AS fiscal_year
    FROM all_dates
),

-- Unknown-date row so fact joins can stay INNER JOINs (COALESCE fact dates to this key)
null_placeholder AS (
    SELECT
        '-1'                       AS date_key,
        CAST(NULL AS DATE)         AS full_date,
        CAST(NULL AS INT64)        AS year,
        CAST(NULL AS INT64)        AS quarter,
        CAST(NULL AS INT64)        AS month,
        CAST(NULL AS STRING)       AS month_name,
        CAST(NULL AS INT64)        AS day_of_month,
        CAST(NULL AS INT64)        AS day_of_week,
        CAST(NULL AS STRING)       AS weekday_name,
        CAST(NULL AS BOOL)         AS is_weekend,
        CAST(NULL AS INT64)        AS fiscal_year
)

SELECT * FROM date_dimension
UNION ALL
SELECT * FROM null_placeholder