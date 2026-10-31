USE [HealthCareAnalysis];

SELECT TOP (20) [Year]
      ,[Facility_Id]
      ,[Facility_Name]
      ,[APR_DRG_Code]
      ,[APR_Severity_of_Illness_Code]
      ,[APR_DRG_Description]
      ,[APR_Severity_of_Illness_Description]
      ,[APR_Medical_Surgical_Code]
      ,[APR_Medical_Surgical_Description]
      ,[Discharges]
      ,[Mean_Charge]
      ,[Median_Charge]
      ,[Mean_Cost]
      ,[Median_Cost]
  FROM [HealthCareAnalysis].[bronze].[cost_transparency]




  SELECT TOP (20) [PermanentFacilityId]
      ,[bronze_id]
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
  FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]





       SELECT COUNT(*) FROM (SELECT DISTINCT Facility_Id FROM bronze.cost_transparency) a
   LEFT JOIN (SELECT DISTINCT PermanentFacilityId FROM bronze.vw_encounters_corrected) b
     ON a.Facility_Id = b.PermanentFacilityId
   WHERE b.PermanentFacilityId IS NULL;

   SELECT DISTINCT a.Facility_Id, a.Facility_Name
FROM bronze.cost_transparency a
LEFT JOIN (SELECT DISTINCT PermanentFacilityId FROM bronze.vw_encounters_corrected) b
    ON a.Facility_Id = b.PermanentFacilityId
WHERE b.PermanentFacilityId IS NULL;

SELECT DISTINCT PermanentFacilityId, FacilityName
FROM bronze.vw_encounters_corrected
WHERE FacilityName LIKE '%Alice Hyde%'
   OR FacilityName LIKE '%Wyoming County%'
   OR FacilityName LIKE '%Koch%'
   OR FacilityName LIKE '%Memorial Sloan%';

      SELECT DISTINCT a.Facility_Id, a.Facility_Name
FROM bronze.cost_transparency a
LEFT JOIN (SELECT DISTINCT PermanentFacilityId FROM bronze.vw_encounters_corrected) b
    ON a.Facility_Id = b.PermanentFacilityId
WHERE b.PermanentFacilityId IS NULL;


 -- WHEN 325 THEN 15485    -- The University of Vermont Health Network - Alice Hyde Medical Center
 -- WHEN 1153 THEN 15620   -- Wyoming County Community Hospital

 CREATE OR ALTER VIEW [bronze].[vw_cost_transparency_corrected] AS
SELECT
    -- Correct the historical facility IDs on the fly
    [Year],
    CASE [Facility_Id]
        WHEN 325  THEN 15485   -- The University of Vermont Health Network - Alice Hyde Medical Center
        WHEN 1153 THEN 15620   -- Wyoming County Community Hospital
        ELSE [Facility_Id]
    END AS [Facility_Id],
    [Facility_Name],
    [APR_DRG_Code],
    [APR_Severity_of_Illness_Code],
    [APR_DRG_Description],
    [APR_Severity_of_Illness_Description],
    [APR_Medical_Surgical_Code],
    [APR_Medical_Surgical_Description],
    [Discharges],
    [Mean_Charge],
    [Median_Charge],
    [Mean_Cost],
    [Median_Cost]
FROM [HealthCareAnalysis].[bronze].[cost_transparency];

SELECT DISTINCT ct.Facility_Id, ct.Facility_Name
FROM bronze.vw_cost_transparency_corrected ct
WHERE NOT EXISTS (
    SELECT 1 FROM bronze.vw_encounters_corrected e
    WHERE e.PermanentFacilityId = ct.Facility_Id
);

   SELECT [Year], Facility_Id, APR_DRG_Code, APR_Severity_of_Illness_Code, COUNT(*) AS n
   FROM bronze.vw_cost_transparency_corrected
   GROUP BY [Year], Facility_Id, APR_DRG_Code, APR_Severity_of_Illness_Code
   HAVING COUNT(*) > 1;

   SELECT COUNT(*) AS enc_rows
FROM bronze.vw_encounters_corrected
WHERE APRDRGCode = 956 OR APRSeverityOfIllnessCode = 0;

 CREATE OR ALTER VIEW [bronze].[vw_cost_transparency_corrected] AS
SELECT
    -- Correct the historical facility IDs on the fly
    [Year],
    CASE [Facility_Id]
        WHEN 325  THEN 15485   -- The University of Vermont Health Network - Alice Hyde Medical Center
        WHEN 1153 THEN 15620   -- Wyoming County Community Hospital
        ELSE [Facility_Id]
    END AS [Facility_Id],
    [Facility_Name],
    [APR_DRG_Code],
    [APR_Severity_of_Illness_Code],
    [APR_DRG_Description],
    [APR_Severity_of_Illness_Description],
    [APR_Medical_Surgical_Code],
    [APR_Medical_Surgical_Description],
    [Discharges],
    [Mean_Charge],
    [Median_Charge],
    [Mean_Cost],
    [Median_Cost]
FROM [HealthCareAnalysis].[bronze].[cost_transparency]
WHERE APR_DRG_Code <> 956 AND APR_Severity_of_Illness_Code > 0;

SELECT TOP (20)
    e.*,
    ct.Discharges     AS benchmark_discharges,
    ct.Mean_Charge    AS benchmark_mean_charge,
    ct.Median_Charge  AS benchmark_median_charge,
    ct.Mean_Cost      AS benchmark_mean_cost,
    ct.Median_Cost    AS benchmark_median_cost
FROM bronze.vw_encounters_corrected e
INNER JOIN bronze.vw_cost_transparency_corrected ct
       ON  ct.[Year]                        = e.DischargeYear
       AND ct.Facility_Id                   = e.PermanentFacilityId
       AND ct.APR_DRG_Code                  = e.APRDRGCode
       AND ct.APR_Severity_of_Illness_Code  = e.APRSeverityOfIllnessCode;


SELECT TOP (20)
    e.bronze_id,
    e.DischargeYear,
    e.PermanentFacilityId,
    e.FacilityName,
    e.APRDRGCode,
    e.APRDRGDescription,
    e.APRSeverityOfIllnessCode,
    e.TotalCharges,
    e.TotalCosts,
    ct.Discharges     AS benchmark_discharges,
    ct.Mean_Charge    AS benchmark_mean_charge,
    ct.Median_Charge  AS benchmark_median_charge,
    ct.Mean_Cost      AS benchmark_mean_cost,
    ct.Median_Cost    AS benchmark_median_cost
FROM bronze.vw_encounters_corrected e
INNER JOIN bronze.vw_cost_transparency_corrected ct
       ON  ct.[Year]                        = e.DischargeYear
       AND ct.Facility_Id                   = e.PermanentFacilityId
       AND ct.APR_DRG_Code                  = e.APRDRGCode
       AND ct.APR_Severity_of_Illness_Code  = e.APRSeverityOfIllnessCode;

/*
Joining encounters to cost_transparency (benchmark_* columns) on year + facility + APR-DRG + severity.

1. Many-to-one: encounters sharing a key repeat the same benchmark values
   (e.g. Montefiore Moses, DRG 58 / severity 2 -> 143 discharges). Don't SUM benchmark_* across encounters.
2. Sources match: for Bellevue DRG 463 / severity 4, benchmark median charge/cost equal the encounter's
   TotalCharges/TotalCosts, so encounters look like the population behind the published aggregates.
3. benchmark money columns are text (e.g. $134,331.45); convert before doing arithmetic.

Scope: cost_transparency only covers 2021, so other years (e.g. 2018) never get a benchmark.
*/

GO;