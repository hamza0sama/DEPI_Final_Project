USE HealthCareAnalysis;
GO

DROP TABLE IF EXISTS silver.facility_information_clean;
GO

;WITH trimmed AS (
    SELECT
        NULLIF(LTRIM(RTRIM(Facility_ID)), '')                  AS Facility_ID,
        NULLIF(LTRIM(RTRIM(Facility_Name)), '')                AS Facility_Name,
        NULLIF(LTRIM(RTRIM(Short_Description)), '')            AS Short_Description,
        NULLIF(LTRIM(RTRIM(Description)), '')                  AS Description,
        Facility_Open_Date,

        CASE WHEN c.a2 = 'Expressway'
             THEN NULLIF(LTRIM(RTRIM(Facility_Address_1)), '') + ' Expressway'
             ELSE NULLIF(LTRIM(RTRIM(Facility_Address_1)), '')
        END                                                    AS Facility_Address_1,

        CASE WHEN c.a2 = 'Expressway'
             THEN NULL
             ELSE NULLIF(LTRIM(RTRIM(
                      REPLACE(REPLACE(' ' + c.a2 + ' ', ' FLR ', ' Floor '), ' FL ', ' Floor '))), '')
        END                                                    AS Facility_Address_2,

        UPPER(NULLIF(LTRIM(RTRIM(Facility_City)), ''))         AS Facility_City,
        NULLIF(LTRIM(RTRIM(Facility_State)), '')               AS Facility_State,
        NULLIF(LTRIM(RTRIM(Facility_Zip_Code)), '')            AS Facility_Zip_Code,
        Facility_Phone_Number,
        NULLIF(LTRIM(RTRIM(Facility_Fax_Number)), '')          AS Facility_Fax_Number,

        NULLIF(LTRIM(RTRIM(
            CASE
                WHEN a.p1 = 0 THEN Facility_Website
                WHEN b.p2 > a.p1
                     THEN COALESCE(NULLIF(SUBSTRING(Facility_Website, a.p1 + 1, b.p2 - a.p1 - 1), ''),
                                   NULLIF(LEFT(Facility_Website, a.p1 - 1), ''))
                ELSE COALESCE(NULLIF(SUBSTRING(Facility_Website, a.p1 + 1, LEN(Facility_Website)), ''),
                              NULLIF(LEFT(Facility_Website, a.p1 - 1), ''))
            END)), '')                                         AS Facility_Website,

        NULLIF(LTRIM(RTRIM(Facility_County_Code)), '')         AS Facility_County_Code,
        UPPER(NULLIF(LTRIM(RTRIM(Facility_County)), ''))       AS Facility_County,
        NULLIF(LTRIM(RTRIM(Regional_Office_ID)), '')           AS Regional_Office_ID,
        NULLIF(LTRIM(RTRIM(Regional_Office)), '')              AS Regional_Office,
        NULLIF(NULLIF(LTRIM(RTRIM(Main_Site_Name)), ''), 'NULL')        AS Main_Site_Name,
        NULLIF(NULLIF(LTRIM(RTRIM(Main_Site_Facility_ID)), ''), 'NULL') AS Main_Site_Facility_ID,
        NULLIF(LTRIM(RTRIM(Operating_Certificate_Number)), '') AS Operating_Certificate_Number,
        Facility_Latitude,
        Facility_Longitude,
        NULLIF(LTRIM(RTRIM(Facility_Location)), '')            AS Facility_Location
    FROM silver.facility_information
    CROSS APPLY (SELECT CHARINDEX('#', Facility_Website) AS p1) a
    CROSS APPLY (SELECT CHARINDEX('#', Facility_Website, a.p1 + 1) AS p2) b
    CROSS APPLY (SELECT LTRIM(RTRIM(Facility_Address_2)) COLLATE Latin1_General_CS_AS AS a2) c
),
cleaned AS (
    SELECT
        Facility_ID,
        Facility_Name,
        Short_Description AS Facility_Type_Code,
        Description       AS Facility_Type,

        CASE
            WHEN Description LIKE '%Extension Clinic%' OR Description LIKE '%Off-Campus%' THEN 'Extension Clinic'
            WHEN Description LIKE '%Hospital%'                                            THEN 'Hospital'
            WHEN Description LIKE '%Diagnostic and Treatment%'                            THEN 'D&T Center'
            WHEN Description LIKE '%Home Care%' OR Description LIKE '%Home Health%'       THEN 'Home Care'
            ELSE 'Other'
        END AS Facility_Category,

        CASE WHEN Facility_Open_Date <= '1901-01-01'
              OR Facility_Open_Date > SYSDATETIME()
             THEN NULL ELSE Facility_Open_Date END AS Facility_Open_Date,
        CASE WHEN Facility_Open_Date = '1901-01-01' THEN 1 ELSE 0 END AS Is_Open_Date_Missing,
        CASE WHEN Facility_Open_Date > '2021-12-31' THEN 1 ELSE 0 END AS Opened_After_Data_Period,

        Facility_Address_1,
        Facility_Address_2,
        Facility_City,
        Facility_State,

        CASE WHEN LEN(Facility_Zip_Code) >= 5
              AND LEFT(Facility_Zip_Code, 5) NOT LIKE '%[^0-9]%'
             THEN LEFT(Facility_Zip_Code, 5) END AS Facility_Zip_Code,

        CASE WHEN Facility_Phone_Number BETWEEN 2000000000 AND 9999999999
             THEN CAST(CAST(Facility_Phone_Number AS BIGINT) AS VARCHAR(10)) END AS Facility_Phone_Number,

        NULLIF(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Facility_Fax_Number,'-',''),' ',''),'(',''),')',''),'.',''),
            '') AS Facility_Fax_Number,

        Facility_Website,
        Facility_County_Code,
        Facility_County,
        Regional_Office_ID,
        Regional_Office,
        Main_Site_Name,
        Main_Site_Facility_ID,
        Operating_Certificate_Number,

        CASE WHEN Facility_Latitude  BETWEEN 40.4 AND 45.1
              AND Facility_Longitude BETWEEN -79.9 AND -71.7
             THEN Facility_Latitude  END AS Facility_Latitude,
        CASE WHEN Facility_Latitude  BETWEEN 40.4 AND 45.1
              AND Facility_Longitude BETWEEN -79.9 AND -71.7
             THEN Facility_Longitude END AS Facility_Longitude,

        Facility_Location,

        ROW_NUMBER() OVER (PARTITION BY Facility_ID ORDER BY Facility_Open_Date DESC) AS rn
    FROM trimmed
    WHERE Facility_ID IS NOT NULL
)
SELECT
    Facility_ID, Facility_Name, Facility_Type_Code, Facility_Type, Facility_Category,
    Facility_Open_Date, Is_Open_Date_Missing, Opened_After_Data_Period,
    Facility_Address_1, Facility_Address_2, Facility_City, Facility_State, Facility_Zip_Code,
    Facility_Phone_Number, Facility_Fax_Number, Facility_Website,
    Facility_County_Code, Facility_County, Regional_Office_ID, Regional_Office,
    Main_Site_Name, Main_Site_Facility_ID, Operating_Certificate_Number,
    Facility_Latitude, Facility_Longitude, Facility_Location,
    CASE WHEN Facility_Latitude IS NULL OR Facility_Longitude IS NULL
         THEN 1 ELSE 0 END AS Is_Location_Missing
INTO silver.facility_information_clean
FROM cleaned
WHERE rn = 1;
GO