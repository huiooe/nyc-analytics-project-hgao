-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           object_id,
           global_id,
           closed_date,
           restaurant,
           legal_name,
           dba_name,
           zip,
           borough,
           building_number,
           street_name,
           business_address,
           bbl,
           latitude,
           longitude,
           permit_id,
           sidewalk_seating_status,
           alcohol_qualification,
           healthcompliance_terms,
           roadway_seating_status,
           submission_time,
           census,
           community_board,
           council,
           landmark_building,
           nta,
           landmark_terms,
           roadway_dimensions_area,
           roadway_dimensions_length,
           roadway_dimensions_width,
           sidewalk_dimensions_area,
           sidewalk_dimensions_length,
           sidewalk_dimensions_width,
           license_type,
           serial_number
       ),

       -- Identifiers
       CAST(objectid AS STRING) AS object_id,
       CAST(globalid AS STRING) AS global_id,
       
       -- Business Name
       CAST(restaurant_name AS STRING) AS restaurant,
       CAST(legal_business_name AS STRING) AS legal_name,
       CAST(doing_business_as_dba AS STRING) AS dba_name,  

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(building_number AS STRING) AS building_number,
       CAST(street AS STRING) AS street_name,
       CAST(business_address AS STRING) AS business_address,
       CAST(bbl AS STRING) AS bbl,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- Application status
       CAST(food_service_establishment AS STRING) AS permit_id,
       CAST(approved_for_sidewalk_seating AS STRING) AS sidewalk_seating_status,
       CAST(qualify_alcohol AS STRING) AS alcohol_qualification,       
       CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
       CAST(approved_for_roadway_seating AS STRING) AS roadway_seating_status,

       -- Date/Time
       CAST(time_of_submission) AS TIMESTAMP) AS submission_time,

       -- district information
       CAST(bbl AS STRING) AS bbl,
       CAST(census_tract AS STRING) AS census,
       CAST(community_board AS STRING) AS community_board,
       CAST(council_district AS STRING) AS council,
       CAST(nta AS STRING) AS nta,

       -- landmark
       CAST(landmark_district_or_building AS STRING) AS landmark_building,
       CAST(landmarkdistrict_terms AS STRING) AS landmark_terms,

       -- dimensions-roadway
       CAST(roadway_dimensions_area AS STRING) AS roadway_dimensions_area,
       CAST(roadway_dimensions_length AS STRING) AS roadway_dimensions_length,
       CAST(roadway_dimensions_width AS STRING) AS roadway_dimensions_width,

       -- dimensions-sidewalk
       CAST(sidewalk_dimensions_area AS STRING) AS sidewalk_dimensions_area,
       CAST(sidewalk_dimensions_length AS STRING) AS sidewalk_dimensions_length,
       CAST(sidewalk_dimensions_width AS STRING) AS sidewalk_dimensions_width,
       
       -- License
       CAST(sla_license_type AS STRING) AS license_type,
       CAST(sla_serial_number AS STRING) AS serial_number,

   FROM source

   -- Filters
   WHERE object_id IS NOT NULL
   AND global_id IS NOT NULL
   AND borough IS NOT NULL

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_open_restaurant_apps.sql
