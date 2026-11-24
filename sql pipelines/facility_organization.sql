USE HealthCareAnalysis;
GO

DROP TABLE IF EXISTS silver.facility_organization_clean;
GO

;WITH trimmed AS (
    SELECT
        NULLIF(LTRIM(RTRIM(Facility_ID)), '') AS Facility_ID,

        -- Operator (collapse double spaces, blank -> NULL)
        NULLIF(REPLACE(LTRIM(RTRIM(Operator_Name)),      '  ', ' '), '') AS Operator_Name,
        NULLIF(REPLACE(LTRIM(RTRIM(Operator_Address_1)), '  ', ' '), '') AS Operator_Address_1,
        NULLIF(REPLACE(LTRIM(RTRIM(Operator_Address_2)), '  ', ' '), '') AS Operator_Address_2,
        UPPER(NULLIF(LTRIM(RTRIM(Operator_City)), ''))                  AS Operator_City,
        NULLIF(LTRIM(RTRIM(Operator_State)), '')                        AS Operator_State,
        NULLIF(LTRIM(RTRIM(Operator_Zip_Code)), '')                     AS Operator_Zip_Code,

        -- Cooperator
        NULLIF(REPLACE(LTRIM(RTRIM(Cooperator_Name)),      '  ', ' '), '') AS Cooperator_Name,
        NULLIF(REPLACE(LTRIM(RTRIM(Cooperator_Address)),   '  ', ' '), '') AS Cooperator_Address,
        NULLIF(REPLACE(LTRIM(RTRIM(Cooperator_Address_2)), '  ', ' '), '') AS Cooperator_Address_2,
        UPPER(NULLIF(LTRIM(RTRIM(Cooperator_City)), ''))                  AS Cooperator_City,
        NULLIF(LTRIM(RTRIM(Cooperator_State)), '')                        AS Cooperator_State,
        NULLIF(LTRIM(RTRIM(Cooperator_Zip_Code)), '')                     AS Cooperator_Zip_Code,

        NULLIF(LTRIM(RTRIM(Ownership_Type)), '') AS Ownership_Type
    FROM silver.facility_organization
),
cleaned AS (
    SELECT
        Facility_ID,
        Operator_Name,
        Operator_Address_1,
        Operator_Address_2,
        Operator_City,
        Operator_State,

        -- keep as VARCHAR so leading zeros survive (e.g. 05401)
        CASE WHEN LEN(Operator_Zip_Code) >= 5
              AND LEFT(Operator_Zip_Code, 5) NOT LIKE '%[^0-9]%'
             THEN LEFT(Operator_Zip_Code, 5) END AS Operator_Zip_Code,

        Cooperator_Name,

        -- "Care of ..." lines: move them to Address_2, street goes to Address_1
        CASE WHEN Cooperator_Address LIKE 'Care of%' AND Cooperator_Address_2 IS NOT NULL
             THEN Cooperator_Address_2 ELSE Cooperator_Address END AS Cooperator_Address,
        CASE WHEN Cooperator_Address LIKE 'Care of%' AND Cooperator_Address_2 IS NOT NULL
             THEN Cooperator_Address   ELSE Cooperator_Address_2 END AS Cooperator_Address_2,

        Cooperator_City,

        -- State is a default value when there is no cooperator, so NULL it
        CASE WHEN Cooperator_Name IS NULL THEN NULL ELSE Cooperator_State END AS Cooperator_State,

        CASE WHEN LEN(Cooperator_Zip_Code) >= 5
              AND LEFT(Cooperator_Zip_Code, 5) NOT LIKE '%[^0-9]%'
             THEN LEFT(Cooperator_Zip_Code, 5) END AS Cooperator_Zip_Code,

        Ownership_Type,
        CASE WHEN Cooperator_Name IS NULL THEN 0 ELSE 1 END AS Has_Cooperator,

        -- remove exact duplicates only; keep one row per (facility, cooperator)
        ROW_NUMBER() OVER (
            PARTITION BY Facility_ID, Operator_Name, Cooperator_Name
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM trimmed
    WHERE Facility_ID IS NOT NULL
)
SELECT
    Facility_ID,
    Operator_Name, Operator_Address_1, Operator_Address_2, Operator_City, Operator_State, Operator_Zip_Code,
    Cooperator_Name, Cooperator_Address, Cooperator_Address_2, Cooperator_City, Cooperator_State, Cooperator_Zip_Code,
    Ownership_Type, Has_Cooperator
INTO silver.facility_organization_clean
FROM cleaned
WHERE rn = 1;
GO

-- Quick checks
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT Facility_ID) AS distinct_facilities,
       SUM(Has_Cooperator) AS rows_with_cooperator
FROM silver.facility_organization_clean;

SELECT Facility_ID
FROM silver.facility_organization_clean o
WHERE NOT EXISTS (SELECT 1 FROM silver.facility_information_clean f WHERE f.Facility_ID = o.Facility_ID);
GO