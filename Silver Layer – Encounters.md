# Silver Layer – Encounters

**Database:** `HealthCareAnalysis`\
**Source:** `bronze.vw_encounters_corrected` (a view over `bronze.encounters`)\
**Target schema:** `silver`\
**File:** `sliver layer for encounters.sql`\
**Dataset:** NY State SPARCS – Hospital Inpatient Discharges

## 1. Purpose

This script builds the Silver layer from the Bronze encounters data. It creates two kinds of objects:

1. One large table, `silver.HospitalDischarges`, with one row per visit, after cleaning columns and converting data types.
2. Small lookup tables (dimensions) built from the same view: a code plus a description.

Every object follows the same pattern: `CREATE TABLE` inside `IF OBJECT_ID(...) IS NULL`, then `GO`, then a `WITH ... INSERT`.

## 2. Execution order

| # | Table | Type | Source |
| --- | --- | --- | --- |
| 1 | `silver.HospitalDischarges` | Main table | `vw_encounters_corrected` |
| 2 | `silver.DimCcsrProcedure` | Dimension | `vw_encounters_corrected` |
| 3 | `silver.DimAprDrg` | Dimension | `vw_encounters_corrected` |
| 4 | `silver.DimAprMdc` | Dimension | `vw_encounters_corrected` |
| 5 | `silver.DimAprSeverityOfIllness` | Dimension | `vw_encounters_corrected` |

The tables do not depend on each other yet (no foreign keys), so the order is not critical.

## 3. Load pattern (CTEs)

```
bronze_latest  →  cleaned  →  INSERT INTO silver.<Table>
```

- **bronze\_latest:** `ROW_NUMBER() OVER (PARTITION BY <key> ORDER BY bronze_id DESC)` keeps the latest row per key.
- **cleaned:** trimming, cleaning and data type conversion.
- **INSERT:** loads only the rows where `rn = 1`.

## 4. Main table: `silver.HospitalDischarges`

**Primary key:** `HospitalDischargesKey` (INT IDENTITY).\
**Grain:** one row per visit (`bronze_id`). `PARTITION BY bronze_id` only guards against duplicates; no rows are dropped.

### 4.1 Columns, data types and cleaning rules

| Column | Type | Cleaning |
| --- | --- | --- |
| HospitalServiceArea | VARCHAR(100) | `NULLIF(TRIM(x), '')` |
| HospitalCounty | VARCHAR(50) | `NULLIF(TRIM(x), '')` |
| OperatingCertificateNumber | INT | `TRY_CAST(NULLIF(TRIM(x),'') AS INT)` |
| PermanentFacilityId | INT | None (already INT in the view) |
| FacilityName | VARCHAR(255) | `NULLIF(TRIM(x), '')` |
| AgeGroup | VARCHAR(20) | `NULLIF(TRIM(x), '')`; values: `0 to 17`, `18 to 29`, `30 to 49`, `50 to 69`, `70 or Older` |
| ZipCode3Digits | VARCHAR(15) | `OOS` becomes `Out of State`; `Unknown` is kept; everything else is trimmed |
| Gender | VARCHAR(10) | `M` becomes Male, `F` becomes Female, `U` becomes Unknown |
| Race | VARCHAR(50) | `NULLIF(TRIM(x), '')` |
| Ethnicity | VARCHAR(50) | `NULLIF(TRIM(x), '')` |
| LengthOfStay | INT | Remove `+` and spaces (for values like `120 +`), then `TRY_CAST` |
| TypeOfAdmission | VARCHAR(30) | `NULLIF(TRIM(x), '')` |
| PatientDisposition | VARCHAR(100) | `NULLIF(TRIM(x), '')` |
| DischargeYear | SMALLINT | `TRY_CAST` |
| CcsrDiagnosisCode | VARCHAR(100) | `NULLIF(TRIM(x), '')`; holds a broad category (body system), not a real code |
| CcsrDiagnosisDescription | VARCHAR(255) | `COVID-19` becomes `CORONAVIRUS DISEASE 2019 (COVID-19)`; the rest is trimmed |
| CcsrProcedureCode | VARCHAR(100) | `NULLIF(TRIM(x), '')` |
| AprDrgCode | INT | `TRY_CAST` |
| AprMdcCode | INT | `TRY_CAST` |
| AprSeverityOfIllnessCode | TINYINT | `TRY_CAST` |
| AprRiskOfMortality | VARCHAR(30) | `NULLIF(TRIM(x), '')` |
| AprMedicalSurgicalDescription | VARCHAR(30) | `NULLIF(TRIM(x), '')` |
| PaymentTypology1 | VARCHAR(100) | `NULLIF(TRIM(x), '')` |
| BirthWeight | INT | `TRY_CAST`; any NULL becomes `0` |
| EmergencyDepartmentIndicator | BIT | `1/Y/YES/TRUE/T` becomes 1; `0/N/NO/FALSE/F` becomes 0; anything else is NULL |
| TotalCharges | DECIMAL(18,2) | Remove `$` and `,`, then `TRY_CAST` |
| TotalCosts | DECIMAL(18,2) | Remove `$` and `,`, then `TRY_CAST` |
| IsNeonate | BIT | Same BIT rule |
| HasSecondaryInsurance | BIT | Same BIT rule |
| CostToChargeRatio | DECIMAL(18,6) | `TRY_CAST` (derived: TotalCosts / TotalCharges) |
| CostChargeDifference | DECIMAL(18,2) | Remove `$` and `,`, then `TRY_CAST` (derived: TotalCharges − TotalCosts) |
| HasProcedure | BIT | Same BIT rule |
| ProcedurePrefix | VARCHAR(50) | `NULLIF(TRIM(x), '')`; contains the value `No Procedure` |
| ProcedureCodeGrouped | VARCHAR(50) | `NULLIF(TRIM(x), '')` |
| LoadDate | DATETIME2(0) | Taken from `load_date` in Bronze |

### 4.2 Notes on data types

- Every column in the view is `nvarchar`, except `PermanentFacilityId` (int), `bronze_id` (int) and `load_date` (datetime2). That is why `TRIM` cannot be applied to `PermanentFacilityId`.
- `TRY_CAST` returns NULL instead of failing when a value cannot be converted, so check the NULL counts after loading.
- `ProcedurePrefix` was widened to 50 after a truncation error on the value `No Procedure`.

## 5. Dimensions

Each dimension holds a code and a description. The code is the primary key.

### 5.1 `silver.DimCcsrProcedure`

| Column | Type | Note |
| --- | --- | --- |
| CcsrProcedureCode | VARCHAR(10) NOT NULL | PK |
| CcsrProcedureDescription | VARCHAR(255) NULL | TRIM only |

### 5.2 `silver.DimAprDrg`

| Column | Type | Note |
| --- | --- | --- |
| AprDrgCode | INT NOT NULL | PK |
| AprDrgDescription | VARCHAR(255) NULL | Abbreviations standardized |

Description cleaning: `W/O` becomes `WITHOUT`, `W` becomes `WITH`, ` EXC  ` becomes ` EXCEPT  `, `&` becomes `AND`, double spaces become one space, then `TRIM`.

### 5.3 `silver.DimAprMdc`

| Column | Type | Note |
| --- | --- | --- |
| AprMdcCode | INT NOT NULL | PK |
| AprMdcDescription | VARCHAR(255) NULL | TRIM only |

### 5.4 `silver.DimAprSeverityOfIllness`

| Column | Type | Note |
| --- | --- | --- |
| AprSeverityOfIllnessCode | TINYINT NOT NULL | PK |
| AprSeverityOfIllnessDescription | VARCHAR(30) NULL | TRIM only |

## 6. Known issues and risks in the current code

| # | Issue | Impact | Suggested fix |
| --- | --- | --- | --- |
| 1 | `HospitalDischarges` has no `BronzeId` and no `NOT EXISTS` | Running the load twice duplicates rows | Add `BronzeId BIGINT NOT NULL UNIQUE` and `NOT EXISTS`, or `TRUNCATE` before each load |
| 2 | The dimensions have no `WHERE code IS NOT NULL` | A NULL code (for example a visit without a procedure) makes the INSERT fail, because the PK rejects NULL | Filter out empty codes |
| 3 | `PARTITION BY` uses the raw column, without TRIM/UPPER | The same code with different spacing counts twice and breaks the PK | Partition by the cleaned code |
| 4 | `DimAprDrg`, `DimAprMdc` and `DimAprSeverityOfIllness`: the code is nvarchar in the view and is inserted into INT/TINYINT by implicit conversion | Fails on any non-numeric value | Use an explicit `TRY_CAST` |
| 5 | `DimCcsrProcedure.CcsrProcedureCode` is VARCHAR(10) | Long text values cause a truncation error | Check `MAX(LEN(...))` and widen the column |
| 6 | The dimensions have no `NOT EXISTS` | Scripts cannot be re-run | Add `NOT EXISTS` |
| 7 | `CcsrDiagnosisCode` in `HospitalDischarges` holds a broad category, not a code | It cannot be a PK or FK on its own | Build the dimension on (code + description) with a surrogate key |
| 8 | `BirthWeight` NULL becomes 0 | Skews averages (adults get weight 0) | Keep NULL |
| 9 | `ROW_NUMBER` over `bronze_id` | No effect if `bronze_id` is already unique | Can be removed |
| 10 | No `USE HealthCareAnalysis` | Connected to `master`, the tables are created in the wrong database | Add `USE` at the top of the file |

## 7. Post-load checks

```sql
-- Row count comparison
SELECT
  (SELECT COUNT(*) FROM silver.HospitalDischarges) AS SilverRows,
  (SELECT COUNT(*) FROM bronze.vw_encounters_corrected) AS BronzeRows;

-- NULLs caused by failed conversions
SELECT
  SUM(CASE WHEN LengthOfStay IS NULL THEN 1 ELSE 0 END) AS NullLOS,
  SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS NullCharges,
  SUM(CASE WHEN IsNeonate    IS NULL THEN 1 ELSE 0 END) AS NullNeonate
FROM silver.HospitalDischarges;

-- Longest text values, before choosing column sizes
SELECT MAX(LEN(ProcedurePrefix)) AS MaxPrefix, MAX(LEN(CCSRProcedureCode)) AS MaxProcCode
FROM bronze.vw_encounters_corrected;
```

## 8. Next steps

- Create `DimCcsrDiagnosis`, `DimFacility` and `DimPatient` (not in this file).
- Add surrogate keys to the dimensions and foreign keys from the fact table.
- Clean the remaining text columns (`UPPER`, normalize symbols such as backticks).
- Build the Gold layer (`FactDischarges` with the dimensions).
