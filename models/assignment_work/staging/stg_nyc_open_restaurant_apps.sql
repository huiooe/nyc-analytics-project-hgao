-- Clean and standardize NYC restaurant outdoor seating applications
-- One row per service request

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns except ones we're transforming
        * EXCEPT (
            objectid,
            globalid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            zip,
            borough,
            bulding_number,
            street,
            business_address,
            bbl,
            latitude,
            longitude,
            food_service_establishment,
            approved_for_sidewalk_seating,
            qualify_alcohol,
            healthcompliance_terms,
            approved_for_roadway_seating,
            time_of_submission,
            census_tract,
            community_board,
            council_district,
            landmark_district_or_building,
            nta,
            landmarkdistrict_terms,
            roadway_dimensions_area,
            roadway_dimensions_length,
            roadway_dimensions_width,
            sidewalk_dimensions_area,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            sla_license_type,
            sla_serial_number
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS object_id,
        CAST(globalid AS STRING) AS global_id,

        -- Business Name
        CAST(restaurant_name AS STRING) AS restaurant,
        CAST(legal_business_name AS STRING) AS legal_name,
        CAST(doing_business_as_dba AS STRING) AS dba_name,  

        -- ZIP code cleaning
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A','NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}$') THEN CAST(zip AS STRING)
            WHEN REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}$') THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,

        -- Borough standardization
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN','NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX','THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN','KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS','QUEEN','QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND','RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CAST(bulding_number AS STRING) AS bulding_number,
        CAST(street AS STRING) AS street_name,
        CAST(business_address AS STRING) AS business_address,
        CAST(bbl AS STRING) AS bbl,
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Application status
        CAST(food_service_establishment AS STRING) AS permit_id,
        CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
        CAST(qualify_alcohol AS STRING) AS alcohol_qualification,       
        CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
        CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- District info
        CAST(census_tract AS STRING) AS census,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council,
        CAST(nta AS STRING) AS nta,

        -- Landmark
        CAST(landmark_district_or_building AS STRING) AS landmark_building,
        CAST(landmarkdistrict_terms AS STRING) AS landmark_terms,

        -- Dimensions - Roadway
        CAST(roadway_dimensions_area AS FLOAT64) AS roadway_dimensions_area,
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_dimensions_length,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_dimensions_width,

        -- Dimensions - Sidewalk
        CAST(sidewalk_dimensions_area AS FLOAT64) AS sidewalk_dimensions_area,
        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_dimensions_length,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_dimensions_width,

        -- License
        CAST(sla_license_type AS STRING) AS license_type,
        CAST(sla_serial_number AS STRING) AS serial_number

    FROM source
    WHERE objectid IS NOT NULL
      AND globalid IS NOT NULL
      AND borough IS NOT NULL
)

SELECT * FROM cleaned