-- Mohamed Ahmed Rashed added the facility information diminsion to the HealthCareAnalysis database and created a new table called facility_information. 
USE HealthCareAnalysis;

-- join should be on the PermanentFacilityId and Facility_ID columns:

SELECT DISTINCT 
    e.FacilityName, 
    f.Facility_Name, 
    e.PermanentFacilityId, 
    f.Facility_ID
FROM [HealthCareAnalysis].[bronze].[encounters] e
LEFT JOIN [HealthCareAnalysis].[bronze].[facility_information] f
    ON e.PermanentFacilityId = f.Facility_ID;

-- it works!

SELECT DISTINCT FacilityName
FROM bronze.encounters


SELECT 
    PermanentFacilityId,
    FacilityName,
    MIN(DischargeYear) AS Earliest_Year,
    MAX(DischargeYear) AS Latest_Year,
    COUNT(*) AS Total_Encounters
FROM [HealthCareAnalysis].[bronze].[encounters]
WHERE FacilityName LIKE '%Cobleskill%'
GROUP BY PermanentFacilityId, FacilityName;

WITH UnmatchedRecords AS (
    -- Step A: Find all encounter rows where the PermanentFacilityId has NO match in the dimension table
    SELECT DISTINCT 
        e.PermanentFacilityId AS [Bad_ID],
        e.FacilityName AS [Reported_Name]
    FROM [HealthCareAnalysis].[bronze].[encounters] e
    LEFT JOIN [HealthCareAnalysis].[bronze].[facility_information] f
        ON e.PermanentFacilityId = f.Facility_ID
    WHERE f.Facility_ID IS NULL
),
ValidFacilityMap AS (
    -- Step B: Get all valid IDs and names from the master dimension table
    SELECT DISTINCT 
        Facility_ID AS [Good_ID],
        Facility_Name AS [Master_Name]
    FROM [HealthCareAnalysis].[bronze].[facility_information]
)
-- Step C: Match them up by name to find the historical-to-active ID mapping
SELECT 
    u.[Bad_ID] AS [Historical_ID],
    v.[Good_ID] AS [Active_Master_ID],
    u.[Reported_Name],
    v.[Master_Name]
FROM UnmatchedRecords u
JOIN ValidFacilityMap v
    -- Compare names (you can use LOWER() or LIKE to account for slight text variations)
    ON LOWER(LTRIM(RTRIM(u.[Reported_Name]))) = LOWER(LTRIM(RTRIM(v.[Master_Name])));


    /* caught all of those historical re-indexing shifts across the entire dataset
    —including Alice Hyde Medical Center, Wyoming County Community Hospital, and Brooks-TLC *؟

    This should be on silver layer as it's a transformation but since I already found a solution
    I'll just write a view for it */


    CREATE OR ALTER VIEW [bronze].[vw_encounters_corrected] AS
SELECT 
    -- 1. Correct the historical facility IDs on the fly
    CASE [PermanentFacilityId]
        WHEN 851 THEN 10216    -- Cobleskill Regional Hospital
        WHEN 325 THEN 15485    -- Alice Hyde Medical Center
        WHEN 1153 THEN 15620   -- Wyoming County Community Hospital
        WHEN 114 THEN 98       -- Brooks-TLC Hospital System
        ELSE [PermanentFacilityId]
    END AS [PermanentFacilityId],
    
    -- 2. Include all other original encounter columns
    [bronze_id]
    ,[HospitalServiceArea]
    ,[HospitalCounty]
    ,[OperatingCertificateNumber]
    ,[FacilityName]
    ,[AgeGroup]
    ,[ZipCode3Digits]
    ,[Gender]
    ,[Race]
    ,[Ethnicity]
    ,[LengthOfStay]
    ,[TypeOfAdmission]
    ,[PatientDisposition]
    ,[DischargeYear]
    ,[CCSRDiagnosisCode]
    ,[CCSRDiagnosisDescription]
    ,[CCSRProcedureCode]
    ,[CCSRProcedureDescription]
    ,[APRDRGCode]
    ,[APRDRGDescription]
    ,[APRMDCCode]
    ,[APRMDCDescription]
    ,[APRSeverityOfIllnessCode]
    ,[APRSeverityOfIllnessDescription]
    ,[APRRiskOfMortality]
    ,[APRMedicalSurgicalDescription]
    ,[PaymentTypology1]
    ,[BirthWeight]
    ,[EmergencyDepartmentIndicator]
    ,[TotalCharges]
    ,[TotalCosts]
    ,[IsNeonate]
    ,[HasSecondaryInsurance]
    ,[CostToChargeRatio]
    ,[CostChargeDifference]
    ,[HasProcedure]
    ,[ProcedurePrefix]
    ,[ProcedureCodeGrouped]
    ,[load_date]

FROM [HealthCareAnalysis].[bronze].[encounters];



-- testing the view:

SELECT DISTINCT 
    e.FacilityName, 
    f.Facility_Name, 
    e.PermanentFacilityId, 
    f.Facility_ID
FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected] e
LEFT JOIN [HealthCareAnalysis].[bronze].[facility_information] f
    ON e.PermanentFacilityId = f.Facility_ID;



    /* 
    still there are 5 unmatched records, 2 due to permanintaly closed facilities, 3 due to not existing in the dimension table.

1.Claxton-Hepburn Medical Center (ID: 798): Operating — Actively providing full emergency and acute inpatient services in Ogdensburg, NY.
2. Cohen Children's Medical Center (ID: 3376):Operating — Fully active in New Hyde Park, NY, as Northwell Health's flagship pediatric facility.
3. The Burdett Care Center (ID: 9250):Operating — Remains open and active as a maternity center housed within Samaritan Hospital in Troy, NY.
4. Eastern Niagara Hospital - Lockport Division (ID: 565):Closed — Permanently shut down in June 2023 following bankruptcy filing.
5. Mount Sinai Beth Israel (ID: 1439):Closed — Formally ceased all patient care operations in July 2024. 

with that I ,Mohamed Ahmed Rashed, have completed the facility information dimension and the necessary transformations to correct historical facility IDs in the HealthCareAnalysis database.
  */
  GO;