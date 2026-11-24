USE HealthCareAnalysis;
GO

DROP TABLE IF EXISTS silver.bridge_facility_operator;
DROP TABLE IF EXISTS silver.bridge_facility_cooperator;
DROP TABLE IF EXISTS silver.dim_operator;
DROP TABLE IF EXISTS silver.dim_cooperator;
GO

SELECT
    ROW_NUMBER() OVER (ORDER BY Operator_Name, Operator_Address_1, Operator_Zip_Code, Ownership_Type) AS Operator_Key,
    Operator_Name, Operator_Address_1, Operator_Address_2,
    Operator_City, Operator_State, Operator_Zip_Code, Ownership_Type
INTO silver.dim_operator
FROM (
    SELECT DISTINCT
        Operator_Name, Operator_Address_1, Operator_Address_2,
        Operator_City, Operator_State, Operator_Zip_Code, Ownership_Type
    FROM silver.facility_organization_clean
    WHERE Operator_Name IS NOT NULL
) d;
GO

SELECT DISTINCT o.Facility_ID, d.Operator_Key
INTO silver.bridge_facility_operator
FROM silver.facility_organization_clean o
JOIN silver.dim_operator d
  ON  d.Operator_Name = o.Operator_Name
  AND ISNULL(d.Operator_Address_1, '') = ISNULL(o.Operator_Address_1, '')
  AND ISNULL(d.Operator_Address_2, '') = ISNULL(o.Operator_Address_2, '')
  AND ISNULL(d.Operator_City, '')      = ISNULL(o.Operator_City, '')
  AND ISNULL(d.Operator_State, '')     = ISNULL(o.Operator_State, '')
  AND ISNULL(d.Operator_Zip_Code, '')  = ISNULL(o.Operator_Zip_Code, '')
  AND ISNULL(d.Ownership_Type, '')     = ISNULL(o.Ownership_Type, '');
GO

SELECT
    ROW_NUMBER() OVER (ORDER BY Cooperator_Name, Cooperator_Address, Cooperator_Zip_Code) AS Cooperator_Key,
    Cooperator_Name, Cooperator_Address, Cooperator_Address_2,
    Cooperator_City, Cooperator_State, Cooperator_Zip_Code
INTO silver.dim_cooperator
FROM (
    SELECT DISTINCT
        Cooperator_Name, Cooperator_Address, Cooperator_Address_2,
        Cooperator_City, Cooperator_State, Cooperator_Zip_Code
    FROM silver.facility_organization_clean
    WHERE Cooperator_Name IS NOT NULL
) d;
GO

-- 4) bridge_facility_cooperator
SELECT DISTINCT o.Facility_ID, d.Cooperator_Key
INTO silver.bridge_facility_cooperator
FROM silver.facility_organization_clean o
JOIN silver.dim_cooperator d
  ON  d.Cooperator_Name = o.Cooperator_Name
  AND ISNULL(d.Cooperator_Address, '')   = ISNULL(o.Cooperator_Address, '')
  AND ISNULL(d.Cooperator_Address_2, '') = ISNULL(o.Cooperator_Address_2, '')
  AND ISNULL(d.Cooperator_City, '')      = ISNULL(o.Cooperator_City, '')
  AND ISNULL(d.Cooperator_State, '')     = ISNULL(o.Cooperator_State, '')
  AND ISNULL(d.Cooperator_Zip_Code, '')  = ISNULL(o.Cooperator_Zip_Code, '');
GO

-- Checks
SELECT
    (SELECT COUNT(*) FROM silver.dim_operator)                      AS operators,
    (SELECT COUNT(*) FROM silver.bridge_facility_operator)          AS facility_operator_links,
    (SELECT COUNT(DISTINCT Facility_ID) FROM silver.bridge_facility_operator) AS facilities_with_operator,
    (SELECT COUNT(*) FROM silver.dim_cooperator)                    AS cooperators,
    (SELECT COUNT(*) FROM silver.bridge_facility_cooperator)        AS facility_cooperator_links;
GO