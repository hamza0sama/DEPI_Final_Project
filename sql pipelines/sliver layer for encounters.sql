IF OBJECT_ID('silver.HospitalDischarges', 'U') IS NULL
BEGIN
    CREATE TABLE silver.HospitalDischarges (
        HospitalDischargesKey            INT IDENTITY(1,1) NOT NULL,
        HospitalServiceArea              VARCHAR(100)    NULL,
        HospitalCounty                   VARCHAR(50)     NULL,
        OperatingCertificateNumber       INT             NULL,
        PermanentFacilityId              INT             NULL,
        FacilityName                     VARCHAR(255)    NULL,
        AgeGroup                         VARCHAR(20)     NULL,
        ZipCode3Digits                   VARCHAR(15)     NULL,
        Gender                           VARCHAR(10)     NULL,
        Race                             VARCHAR(50)     NULL,
        Ethnicity                        VARCHAR(50)     NULL,
        LengthOfStay                     INT             NULL,
        TypeOfAdmission                  VARCHAR(30)     NULL,
        PatientDisposition               VARCHAR(100)    NULL,
        DischargeYear                    SMALLINT        NULL,
        CcsrDiagnosisCode                VARCHAR(100)    NULL,
        CcsrDiagnosisDescription         VARCHAR(255)    NULL,
        CcsrProcedureCode                VARCHAR(100)    NULL,
        AprDrgCode                       INT             NULL,
        AprMdcCode                       INT             NULL,
        AprSeverityOfIllnessCode         TINYINT         NULL,
        AprRiskOfMortality               VARCHAR(30)     NULL,
        AprMedicalSurgicalDescription    VARCHAR(30)     NULL,
        PaymentTypology1                 VARCHAR(100)    NULL,
        BirthWeight                      INT             NULL,
        EmergencyDepartmentIndicator     BIT             NULL,
        TotalCharges                     DECIMAL(18,2)   NULL,
        TotalCosts                       DECIMAL(18,2)   NULL,
        IsNeonate                        BIT             NULL,
        HasSecondaryInsurance            BIT             NULL,
        CostToChargeRatio                DECIMAL(18,6)   NULL,
        CostChargeDifference             DECIMAL(18,2)   NULL,
        HasProcedure                     BIT             NULL,
        ProcedurePrefix                  VARCHAR(50)     NULL,
        ProcedureCodeGrouped             VARCHAR(50)     NULL,
        LoadDate                         DATETIME2(0)    NULL,
        CONSTRAINT PK_HospitalDischarges PRIMARY KEY (HospitalDischargesKey)
    );
END
go
WITH bronze_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY bronze_id ORDER BY bronze_id DESC) AS rn
    FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]
),
cleaned AS (
    SELECT
        -- نصوص
        NULLIF(TRIM(HospitalServiceArea), '')  AS HospitalServiceArea,
        NULLIF(TRIM(HospitalCounty), '')       AS HospitalCounty,
        NULLIF(TRIM(FacilityName), '')         AS FacilityName,
        NULLIF(TRIM(AgeGroup), '')             AS AgeGroup,
        NULLIF(TRIM(Race), '')                 AS Race,
        NULLIF(TRIM(Ethnicity), '')            AS Ethnicity,
        NULLIF(TRIM(TypeOfAdmission), '')      AS TypeOfAdmission,
        NULLIF(TRIM(PatientDisposition), '')   AS PatientDisposition,
        NULLIF(TRIM(CCSRDiagnosisCode), '')    AS CcsrDiagnosisCode,
        NULLIF(TRIM(CCSRProcedureCode), '')    AS CcsrProcedureCode,
        NULLIF(TRIM(APRRiskOfMortality), '')   AS AprRiskOfMortality,
        NULLIF(TRIM(APRMedicalSurgicalDescription), '') AS AprMedicalSurgicalDescription,
        NULLIF(TRIM(PaymentTypology1), '')     AS PaymentTypology1,
        NULLIF(TRIM(ProcedurePrefix), '')      AS ProcedurePrefix,
        NULLIF(TRIM(ProcedureCodeGrouped), '') AS ProcedureCodeGrouped,

        CASE
            WHEN TRIM(ZipCode3Digits) = 'OOS'     THEN 'Out of State'
            WHEN TRIM(ZipCode3Digits) = 'Unknown' THEN 'Unknown'
            ELSE NULLIF(TRIM(ZipCode3Digits), '')
        END AS ZipCode3Digits,

        CASE
            WHEN TRIM(Gender) = 'M' THEN 'Male'
            WHEN TRIM(Gender) = 'F' THEN 'Female'
            WHEN TRIM(Gender) = 'U' THEN 'Unknown'
            ELSE NULLIF(TRIM(Gender), '')
        END AS Gender,

        CASE
            WHEN TRIM(CCSRDiagnosisDescription) = 'COVID-19'
                THEN 'CORONAVIRUS DISEASE 2019 (COVID-19)'
            ELSE NULLIF(TRIM(CCSRDiagnosisDescription), '')
        END AS CcsrDiagnosisDescription,

        -- أرقام
        TRY_CAST(NULLIF(TRIM(OperatingCertificateNumber), '') AS INT)  AS OperatingCertificateNumber,
        PermanentFacilityId                                            AS PermanentFacilityId,   
        TRY_CAST(NULLIF(REPLACE(REPLACE(TRIM(LengthOfStay), '+', ''), ' ', ''), '') AS INT) AS LengthOfStay,
        TRY_CAST(NULLIF(TRIM(DischargeYear), '') AS SMALLINT)          AS DischargeYear,
        TRY_CAST(NULLIF(TRIM(APRDRGCode), '') AS INT)                  AS AprDrgCode,
        TRY_CAST(NULLIF(TRIM(APRMDCCode), '') AS INT)                  AS AprMdcCode,
        TRY_CAST(NULLIF(TRIM(APRSeverityOfIllnessCode), '') AS TINYINT) AS AprSeverityOfIllnessCode,
        ISNULL(TRY_CAST(NULLIF(TRIM(BirthWeight), '') AS INT), 0)      AS BirthWeight,

        -- فلوس
        TRY_CAST(NULLIF(REPLACE(REPLACE(TRIM(TotalCharges), '$', ''), ',', ''), '') AS DECIMAL(18,2)) AS TotalCharges,
        TRY_CAST(NULLIF(REPLACE(REPLACE(TRIM(TotalCosts), '$', ''), ',', ''), '') AS DECIMAL(18,2))   AS TotalCosts,
        TRY_CAST(NULLIF(TRIM(CostToChargeRatio), '') AS DECIMAL(18,6))                                AS CostToChargeRatio,
        TRY_CAST(NULLIF(REPLACE(REPLACE(TRIM(CostChargeDifference), '$', ''), ',', ''), '') AS DECIMAL(18,2)) AS CostChargeDifference,

        -- BIT
        CASE WHEN UPPER(TRIM(EmergencyDepartmentIndicator)) IN ('1','Y','YES','TRUE','T') THEN 1
             WHEN UPPER(TRIM(EmergencyDepartmentIndicator)) IN ('0','N','NO','FALSE','F') THEN 0 END AS EmergencyDepartmentIndicator,
        CASE WHEN UPPER(TRIM(IsNeonate)) IN ('1','Y','YES','TRUE','T') THEN 1
             WHEN UPPER(TRIM(IsNeonate)) IN ('0','N','NO','FALSE','F') THEN 0 END AS IsNeonate,
        CASE WHEN UPPER(TRIM(HasSecondaryInsurance)) IN ('1','Y','YES','TRUE','T') THEN 1
             WHEN UPPER(TRIM(HasSecondaryInsurance)) IN ('0','N','NO','FALSE','F') THEN 0 END AS HasSecondaryInsurance,
        CASE WHEN UPPER(TRIM(HasProcedure)) IN ('1','Y','YES','TRUE','T') THEN 1
             WHEN UPPER(TRIM(HasProcedure)) IN ('0','N','NO','FALSE','F') THEN 0 END AS HasProcedure,

        load_date AS LoadDate  
    FROM bronze_latest
    WHERE rn = 1
)
INSERT INTO silver.HospitalDischarges (
    HospitalServiceArea, HospitalCounty, OperatingCertificateNumber, PermanentFacilityId,
    FacilityName, AgeGroup, ZipCode3Digits, Gender, Race, Ethnicity,
    LengthOfStay, TypeOfAdmission, PatientDisposition, DischargeYear,
    CcsrDiagnosisCode, CcsrDiagnosisDescription, CcsrProcedureCode,
    AprDrgCode, AprMdcCode, AprSeverityOfIllnessCode,
    AprRiskOfMortality, AprMedicalSurgicalDescription, PaymentTypology1,
    BirthWeight, EmergencyDepartmentIndicator, TotalCharges, TotalCosts,
    IsNeonate, HasSecondaryInsurance, CostToChargeRatio, CostChargeDifference,
    HasProcedure, ProcedurePrefix, ProcedureCodeGrouped, LoadDate
)
SELECT
    HospitalServiceArea, HospitalCounty, OperatingCertificateNumber, PermanentFacilityId,
    FacilityName, AgeGroup, ZipCode3Digits, Gender, Race, Ethnicity,
    LengthOfStay, TypeOfAdmission, PatientDisposition, DischargeYear,
    CcsrDiagnosisCode, CcsrDiagnosisDescription, CcsrProcedureCode,
    AprDrgCode, AprMdcCode, AprSeverityOfIllnessCode,
    AprRiskOfMortality, AprMedicalSurgicalDescription, PaymentTypology1,
    BirthWeight, EmergencyDepartmentIndicator, TotalCharges, TotalCosts,
    IsNeonate, HasSecondaryInsurance, CostToChargeRatio, CostChargeDifference,
    HasProcedure, ProcedurePrefix, ProcedureCodeGrouped, LoadDate
FROM cleaned;
GO











/*
creating DimCcsrProcedure 
*/

IF OBJECT_ID('silver.DimCcsrProcedure', 'U') IS NULL
BEGIN
    CREATE TABLE silver.DimCcsrProcedure (
        CcsrProcedureCode         VARCHAR(10)   NOT NULL,
        CcsrProcedureDescription  VARCHAR(255)  NULL,

        CONSTRAINT PK_DimCcsrProcedure PRIMARY KEY (CcsrProcedureCode)
    );
END
GO
WITH bronze_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY CcsrProcedureCode ORDER BY bronze_id DESC) AS rn
  FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]

),

cleaned AS (
    SELECT
    TRIM(CcsrProcedureCode) as CcsrProcedureCode,
    TRIM(CcsrProcedureDescription) as CcsrProcedureDescription
    from bronze_latest 
     WHERE rn = 1)
     INSERT into silver.DimCcsrProcedure( CcsrProcedureCode,CcsrProcedureDescription)
        SELECT CcsrProcedureCode,CcsrProcedureDescription
        from cleaned ;
        go











/*
creating  DimAprDrg
*/

IF OBJECT_ID('silver.DimAprDrg', 'U') IS NULL
BEGIN
    CREATE TABLE silver.DimAprDrg (
        AprDrgCode         INT           NOT NULL,
        AprDrgDescription  VARCHAR(255)  NULL,

        CONSTRAINT PK_DimAprDrg PRIMARY KEY (AprDrgCode)
    );
END
GO
WITH bronze_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY AprDrgCode   ORDER BY bronze_id DESC) AS rn
  FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]

),

cleaned AS (
select
   AprDrgCode,
       
        TRIM(REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(AprDrgDescription, 'W/O', 'WITHOUT'),
                        ' W ', ' WITH '),
                    'EXC ', 'EXCEPT '),
                '&', 'AND'),
            '  ', ' ')
        ) AS AprDrgDescription
    FROM bronze_latest 
    WHERE rn = 1)
INSERT INTO silver.DimAprDrg (AprDrgCode, AprDrgDescription)
SELECT AprDrgCode, AprDrgDescription
FROM cleaned;
GO









/*

creating  DimAprMdc
*/
IF OBJECT_ID('silver.DimAprMdc', 'U') IS NULL
BEGIN
    CREATE TABLE silver.DimAprMdc (
        AprMdcCode         INT           NOT NULL,
        AprMdcDescription  VARCHAR(255)  NULL,

        CONSTRAINT PK_DimAprMdc PRIMARY KEY (AprMdcCode)
    );
END
GO

WITH bronze_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY AprMdcCode   ORDER BY bronze_id DESC) AS rn
  FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]

),
cleaned as (  SELECT
        TRIM(AprMdcCode) as AprMdcCode ,
        TRIM(AprMdcDescription) as AprMdcDescription
        From bronze_latest
        where rn=1)

        INSERT INTO silver.DimAprMdc (AprMdcCode, AprMdcDescription)
SELECT AprMdcCode, AprMdcDescription
FROM cleaned;
GO






















IF OBJECT_ID('silver.DimAprSeverityOfIllness', 'U') IS NULL
BEGIN
    CREATE TABLE silver.DimAprSeverityOfIllness (
        AprSeverityOfIllnessCode         TINYINT      NOT NULL,
        AprSeverityOfIllnessDescription  VARCHAR(30)  NULL,

        CONSTRAINT PK_DimAprSeverityOfIllness PRIMARY KEY (AprSeverityOfIllnessCode)
    );
END
GO
WITH bronze_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY AprSeverityOfIllnessCode   ORDER BY bronze_id DESC) AS rn
  FROM [HealthCareAnalysis].[bronze].[vw_encounters_corrected]

),
cleaned as (  SELECT
        TRIM( AprSeverityOfIllnessDescription) as  AprSeverityOfIllnessDescription ,
        TRIM(AprSeverityOfIllnessCode    ) as AprSeverityOfIllnessCode    
        From bronze_latest
        where rn=1)
                INSERT INTO silver.DimAprSeverityOfIllness (AprSeverityOfIllnessCode    ,  AprSeverityOfIllnessDescription)
SELECT AprSeverityOfIllnessCode    ,  AprSeverityOfIllnessDescription
FROM cleaned;
GO
