# CareLens Power BI Dashboard Build Guide

This guide covers the ten dashboard pages in the PBIP project: what each page is for, what was actually built, and where the build differs from the original plan. All ten pages now exist. Pages 8 and 9 are partial because two pieces of source data are missing (see 1.1). The shared semantic model is the source of truth, and contributors should still work in copies/branches and merge pages and measures carefully.

The change log for the latest build is in `BUILD_NOTES.md`. Where this guide and the report disagree, the report wins.

## 1. Before building any visual

### 1.1 Confirm the model scope

Open the PBIP project and verify:

- `gold Fact_Discharges` is the central fact table.
- Dimension relationships are active from the fact table to Year, Facility, Patient, Admission, Payment, Diagnosis, Procedure, APR-DRG, APR-MDC, Severity, and Medical/Surgical.
- Facility-to-Operator and Facility-to-Cooperator relationships use the bridge tables.
- The model refreshes successfully.

The report has ten pages, all 1280x720. The model still does not expose `Fact_CostTransparency`, and `BirthWeight` is still removed from the fact query. Do not create visuals that depend on those fields until the model is updated. Pages 8 and 9 each carry a short note saying what is missing.

The data covers four years, 2018-2021. Older planning text mentions 2022-2023; ignore it.

### 1.2 Refresh and document the baseline

1. Open the project in Power BI Desktop.
2. Refresh the model.
3. Confirm that the refresh completes without credential, relationship, or privacy errors.
4. Record the row count of `gold Fact_Discharges`, the available years (2018-2021), and any refresh warnings.
5. Save a working copy before contributors add pages.

Do not share or commit database credentials. Use the existing project connection configuration and the team's approved secret-handling process.

### 1.3 Recommended report-wide settings

- Canvas: 16:9 at 1280x720. The earlier 1920x1080 canvas made text too small once it was fit to the screen; text is now 10-12 pt.
- Theme: `MedicalTheme` on top of the Fluent base. Auto-subtitles are off, lines are straight (not smoothed), and slicer padding is slimmer so dropdowns are not cropped.
- Colour has a fixed meaning: volume teal, costs navy, charges slate, LOS amber, neonatal violet.
- Keep a consistent left-to-right reading order.
- The footer is the `Footer Text` measure (data period, load date, "de-identified inpatient discharge data" and the charges caveat).
- Use synced slicers only for dimensions that filter the page correctly.
- Use report/page tooltips for extra metrics rather than adding many visuals.

## 2. Create the reusable measures first

These measures already exist in `gold Fact_Discharges`, sorted into display folders (see the list after this section). The code below is kept as a reference for the core definitions. Don't recreate them; if you change one, change it in the model so every page picks it up. Do not change relationship behavior.

Use the exact table and column names from the model. The measure names below are intentionally reused across pages.

```DAX
Total Discharges =
COUNTROWS ( 'gold Fact_Discharges' )

Total Charges =
SUM ( 'gold Fact_Discharges'[TotalCharges] )

Total Costs =
SUM ( 'gold Fact_Discharges'[TotalCosts] )

Average LOS =
AVERAGE ( 'gold Fact_Discharges'[LengthOfStay] )

Average Cost per Discharge =
DIVIDE ( [Total Costs], [Total Discharges] )

Average Charge per Discharge =
DIVIDE ( [Total Charges], [Total Discharges] )

Cost-to-Charge Ratio =
DIVIDE ( [Total Costs], [Total Charges] )

Charge-Cost Difference =
[Total Charges] - [Total Costs]

Emergency Discharges =
CALCULATE (
    [Total Discharges],
    'gold Dim_Admission'[EmergencyDepartmentIndicator] = 1
)

Emergency Share =
DIVIDE ( [Emergency Discharges], [Total Discharges] )

Procedure Discharges =
CALCULATE (
    [Total Discharges],
    'gold Fact_Discharges'[HasProcedure] = TRUE ()
)

Procedure Share =
DIVIDE ( [Procedure Discharges], [Total Discharges] )

Neonatal Discharges =
CALCULATE (
    [Total Discharges],
    'gold Fact_Discharges'[IsNeonate] = TRUE ()
)

Neonatal Share =
DIVIDE ( [Neonatal Discharges], [Total Discharges] )

Secondary Insurance Discharges =
CALCULATE (
    [Total Discharges],
    'gold Fact_Discharges'[HasSecondaryInsurance] = TRUE ()
)

Secondary Insurance Share =
DIVIDE ( [Secondary Insurance Discharges], [Total Discharges] )

Expired Discharges =
CALCULATE (
    [Total Discharges],
    'gold Dim_Admission'[PatientDisposition] = "Expired"
)

Mortality Share =
DIVIDE ( [Expired Discharges], [Total Discharges] )

Discharges Previous Year =
VAR SelectedYear = MAX ( 'gold Dim_Year'[Year] )
RETURN
    CALCULATE (
        [Total Discharges],
        FILTER (
            ALL ( 'gold Dim_Year'[Year] ),
            'gold Dim_Year'[Year] = SelectedYear - 1
        )
    )

Discharges YoY % =
DIVIDE (
    [Total Discharges] - [Discharges Previous Year],
    [Discharges Previous Year]
)

Charges Previous Year =
VAR SelectedYear = MAX ( 'gold Dim_Year'[Year] )
RETURN
    CALCULATE (
        [Total Charges],
        FILTER (
            ALL ( 'gold Dim_Year'[Year] ),
            'gold Dim_Year'[Year] = SelectedYear - 1
        )
    )

Costs Previous Year =
VAR SelectedYear = MAX ( 'gold Dim_Year'[Year] )
RETURN
    CALCULATE (
        [Total Costs],
        FILTER (
            ALL ( 'gold Dim_Year'[Year] ),
            'gold Dim_Year'[Year] = SelectedYear - 1
        )
    )

Charges YoY % =
DIVIDE ( [Total Charges] - [Charges Previous Year], [Charges Previous Year] )

Costs YoY % =
DIVIDE ( [Total Costs] - [Costs Previous Year], [Costs Previous Year] )
```

### Measure formatting

- Counts: whole number with thousands separator.
- Currency: choose one currency and use it consistently; include the currency symbol in titles.
- Ratios: percentage with one decimal place.
- LOS: one decimal place followed by "days" in the visual title.
- YoY: percentage with one decimal place.

### Per-discharge measures

These three are in folder `1 Core`. Use them rather than the built-in visual aggregation so every page shows the same number:

```DAX
Average Total Cost =
AVERAGE ( 'gold Fact_Discharges'[TotalCosts] )

Average Total Charge =
AVERAGE ( 'gold Fact_Discharges'[TotalCharges] )

Average Cost-to-Charge Ratio =
AVERAGE ( 'gold Fact_Discharges'[CostToChargeRatio] )
```

Use `SUM` for total costs/charges and `AVERAGE` for per-discharge metrics. Never sum `CostToChargeRatio` across rows.

### Measures added during the build

The model now has 66 measures in nine folders. The core, share and year-over-year measures above are in folders 1 to 3. The rest were added as the pages needed them.

| Folder | What is in it |
|---|---|
| 1 Core | Totals, averages, cost-to-charge, charge-cost difference, `Facility Count` |
| 2 Shares | Emergency, procedure, neonatal, secondary insurance, expired (mortality), extreme severity, `Top 5 Facilities Share` |
| 3 Time | Previous/current year, change, YoY % and absolute change for discharges, charges, costs and LOS |
| 4 Scenario | `Scenario Discharges - Flat`, `Scenario Discharges - Trend Continues`, `Scenario Costs - Trend Continues` |
| 5 Neonatal | Neonatal average LOS, average cost, expired discharges, mortality share |
| 6 Facility Quality | Open date missing, location missing, opened after data period, `Unmapped Facility Discharges` |
| 7 Ownership | Operator and cooperator counts, linked facility counts, operator discharges, costs, average cost and LOS |
| 8 Footer | `Data Period`, `Footer Text` |
| 9 Comparison and Ranking | Emergency / non-emergency average LOS, and the `Ranked ...` measures |

Two things to know:

- The `Ranked ...` measures (average LOS, average cost per discharge, extreme severity share, discharges absolute change) return blank below 100 discharges. Top N visuals are built on these so the ranking only covers groups big enough to compare. Filtering a minimum volume after Top N can leave a handful of bars.
- Facility, operator and cooperator counts only include facilities that have discharges. The facility registry is much bigger than that set, and counting all of it made the cards disagree with the charts. `Unmapped Facility Discharges` counts discharges with no facility record.

## 3. Shared page pattern

Use this layout on every page:

1. **Header:** page title and a one-sentence decision question.
2. **Left filter rail:** synced Year, Facility type and County slicers, one page-specific slicer, and a short "how to read" note.
3. **KPI row:** cards with explicit units and precision (for example 8.81M, $555.1bn, $19,059), not auto-rounded values.
4. **Two rows of charts:** a trend or ranking first, then comparisons and one table/matrix where it helps.
5. **Footer:** the dynamic `Footer Text` measure.

Keep each page to roughly six to eight visuals on the grid, with units in the titles.

For each ranking chart:

- Sort descending by the intended measure.
- Apply a Top N filter only after choosing the correct measure.
- Use the `Ranked ...` measures where very small groups could distort average cost, LOS or a share.
- Facility rankings have a not-blank filter, so the group with no facility record does not show up as "(Blank)".
- Turn on data labels only when they remain readable.

## 4. Dashboard 1 - Executive Overview

**Owner:** Hamza  
**Purpose:** establish scale, change, financial totals, and the largest facilities.

**Status:** built. Cards for discharges, charges, costs, average cost, average LOS, growth vs. prior year, top-5 facility share, procedure, emergency and neonatal share. Charts: discharges by year, charges vs. costs by year, case mix by year, top 5 facilities, and a year summary table. Slicers: Year, Regional office, Facility type, County.

### Build steps

1. Rename the page `01 Executive Overview`.
2. Add KPI cards for:
   - `[Total Discharges]`
   - `[Total Charges]`
   - `[Total Costs]`
   - `[Average Cost per Discharge]`
   - `[Average LOS]`
3. Add a clustered column or line chart:
   - X-axis: `gold Dim_Year[Year]`
   - Values: `[Total Discharges]`, `[Total Charges]`, `[Total Costs]`
   - Use separate charts if the currency scale hides discharge volume.
4. Add cards for `[Discharges YoY %]`, `[Emergency Share]`, `[Procedure Share]`, and `[Neonatal Share]`.
5. Add a bar chart:
   - Y-axis: `gold Dim_Facility[Facility_Name]`
   - X-axis: `[Total Discharges]`
   - Visual filter: Top 5 by `[Total Discharges]`.
6. Add slicers for Year, Facility Type, and Facility County.
7. Add a tooltip with total cost, average LOS, and cost-to-charge ratio to the facility chart.

### Answers to verify

- Is volume higher or lower in the later year?
- Do costs move in the same direction as discharges?
- Are the top five facilities a large share of volume?
- Are emergency/procedure/neonatal shares materially different by year?

## 5. Dashboard 2 - Cost & Charges Analysis

**Owner:** Hamza  
**Purpose:** explain the difference between charges, costs, and average financial intensity.

**Status:** built. Cards for charges, costs, the charge-cost gap and the ratio. Charts: charges vs. costs by year, top 10 facilities by gap, average cost by facility type, top 10 diagnoses by total cost, a payment-type matrix, and a cost-vs-charge scatter limited to sites with 1,000+ discharges. The separate top-10-by-average-cost diagnosis chart lives on page 5. Extra slicer: Payment type.

### Build steps

1. Rename the page `02 Cost and Charges`.
2. Add KPI cards for `[Total Charges]`, `[Total Costs]`, `[Charge-Cost Difference]`, and `[Cost-to-Charge Ratio]`.
3. Add a clustered column chart:
   - Axis: `gold Dim_Year[Year]`
   - Values: `[Total Charges]` and `[Total Costs]`.
4. Add a ranked bar chart by `Facility_Name` with `[Charge-Cost Difference]`.
5. Add a column chart:
   - Axis: `Facility_Type` or `Facility_Category`
   - Value: `[Average Cost per Discharge]`.
6. Add a scatter chart:
   - X: `[Average Total Cost]` or average `TotalCosts`
   - Y: `[Average Total Charge]` or average `TotalCharges`
   - Size: `[Total Discharges]`
   - Details: Facility Name or diagnosis description.
7. Add a matrix:
   - Rows: `Dim_Payment[PaymentTypology1]`
   - Values: `[Total Discharges]`, `[Average Cost per Discharge]`, `[Cost-to-Charge Ratio]`.
8. Add a diagnosis bar chart with Top 10 by total cost and a separate Top 10 by average cost per case.

### Interpretation caution

Charges are not necessarily collected revenue, and a low cost-to-charge ratio is not automatically better. Use "financial variation" and "benchmarking signal," not "profit" or "quality."

## 6. Dashboard 3 - Length of Stay & Admission

**Owner:** Seif el deen  
**Purpose:** explain patient flow and capacity pressure.

**Status:** built. Charts: discharges by LOS band, average LOS by admission type, top 8 dispositions, longest average stay by facility (ranked), LOS-vs-cost scatter (1,000+ discharges), and an expired-share matrix by admission type and year. Emergency and non-emergency LOS are two side-by-side cards rather than a clustered chart. Extra slicer: Admission type.

### Build steps

1. Rename the page `03 Length of Stay and Admission`.
2. The model already has a `LOS Band` calculated column (and `LOS Band Order`, which sorts it). The definition is kept here for reference:

```DAX
LOS Band =
SWITCH (
    TRUE (),
    'gold Fact_Discharges'[LengthOfStay] <= 1, "1 day",
    'gold Fact_Discharges'[LengthOfStay] <= 3, "2-3 days",
    'gold Fact_Discharges'[LengthOfStay] <= 7, "4-7 days",
    'gold Fact_Discharges'[LengthOfStay] <= 14, "8-14 days",
    "15+ days"
)
```

Use `LOS Band Order` as the sort column so the bands read in stay order, not alphabetically.
3. Add a column chart of LOS band by `[Total Discharges]`.
4. Add a bar chart of `TypeOfAdmission` by `[Average LOS]`.
5. Add a bar chart of `PatientDisposition` by `[Total Discharges]`.
6. Add a clustered comparison of emergency versus non-emergency:
   - Axis: `EmergencyDepartmentIndicator`
   - Values: `[Average LOS]`, `[Average Cost per Discharge]`.
7. Add a facility ranking by `[Average LOS]`, with a minimum-volume filter.
8. Add a matrix with Year and admission type showing `[Mortality Share]`.
9. Add a scatter chart with LOS on X, average cost on Y, and discharge count as size.

### Interpretation caution

Disposition "Expired" is a recorded discharge disposition, not a causal mortality analysis. Use "mortality share in the discharge data."

## 7. Dashboard 4 - Patient Demographics & Payment

**Owner:** Seif el deen  
**Purpose:** describe the patient population, origin, and payer mix.

**Status:** built, with the matrix and treemap dropped. Charts: discharges by age group, gender mix by age (100%), race, ethnicity, primary payer, payer mix by age (100%), and the top 10 ZIP-3 areas as a bar chart rather than a map. Race/ethnicity cost and LOS are in tooltips instead of a matrix. Extra slicer: Age group.

### Build steps

1. Rename the page `04 Patient Demographics and Payment`.
2. Add a column chart of `Dim_Patient[AgeGroup]` by `[Total Discharges]`.
3. Add a 100% stacked column chart:
   - X-axis: AgeGroup
   - Legend: Gender
   - Values: `[Total Discharges]`.
4. Add separate bar/donut charts for Race and Ethnicity; use bars when there are many categories.
5. Add a treemap or ranked bar chart for `PaymentTypology1`.
6. Add a 100% stacked bar:
   - Axis: AgeGroup
   - Legend: PaymentTypology1
   - Values: `[Total Discharges]`.
7. Add a card for `[Secondary Insurance Share]`.
8. Add a map or bar chart for `ZipCode3Digits`. If using a map, classify the field correctly and include an "Unknown" category in a data-quality note.
9. Add a matrix by Race/Ethnicity with `[Total Discharges]`, `[Average Cost per Discharge]`, and `[Average LOS]`.

### Interpretation caution

Demographic differences are descriptive. Do not state that demographic identity causes cost or LOS differences.

## 8. Dashboard 5 - Diagnosis & Procedure

**Owner:** Mohamed Rashed  
**Purpose:** identify the conditions and procedures driving demand and resource use.

**Status:** built, trimmed. Charts: top 10 diagnoses by discharges, by total cost and by cost per case (ranked), top 10 procedures by discharges, and a decomposition tree on total cost. The procedure-by-cost chart and the diagnosis x procedure matrix were dropped. Extra slicer: Age group.

### Build steps

1. Rename the page `05 Diagnosis and Procedure`.
2. Add a Top 10 diagnosis bar chart by `[Total Discharges]`.
3. Duplicate it and change the value to `[Total Costs]`.
4. Add a third diagnosis chart using average `TotalCosts` per discharge; apply a minimum-volume filter.
5. Add Top 10 procedure charts by volume and total cost.
6. Add a diagnosis chart with the percentage of procedure-involving discharges. Use `[Procedure Share]` with diagnosis as the axis.
7. Add a matrix:
   - Rows: diagnosis description
   - Columns: procedure description
   - Values: `[Total Discharges]`.
8. Add a diagnosis ranking by `[Average LOS]`.
9. Add a decomposition tree with:
   - Analyze: `[Total Costs]` or `[Total Discharges]`
   - Explain by: Diagnosis, AgeGroup, Gender, Procedure, Facility Type, and Year.

### Interpretation caution

Separate high-volume, high-total-cost, and high-average-cost diagnoses. They answer different operational questions.

## 9. Dashboard 6 - Severity, APR-DRG & MDC

**Owner:** Mohamed Rashed  
**Purpose:** explain the clinical complexity gradient behind cost and LOS.

**Status:** built. Charts: discharges by severity, discharges by severity and risk of mortality (one chart instead of a matrix), cost and LOS by severity (combo), top 10 APR-DRGs by discharges and by total cost, and MDCs by extreme-severity share (ranked). Medical/surgical is a slicer, not a donut.

### Build steps

1. Rename the page `06 Severity and Clinical Complexity`.
2. Add a column chart of `AprSeverityOfIllnessDescription` by `[Total Discharges]`.
3. Add a bar chart of `AprRiskOfMortality` by `[Total Discharges]`.
4. Add a matrix:
   - Rows: severity description
   - Columns: risk of mortality
   - Values: `[Total Discharges]`, `[Average LOS]`, `[Average Cost per Discharge]`.
5. Add a line/column chart by severity with average LOS and average cost. Use separate visuals if scales conflict.
6. Add Top 10 APR-DRG charts by volume and total cost.
7. Add an MDC chart by volume and total cost.
8. Add a 100% stacked bar or donut for `AprMedicalSurgicalDescription`.
9. Add a bar chart of MDC by extreme-severity share. Use a minimum-volume filter.
10. Add Year and Facility Type slicers so the severity mix can be compared over time and by facility type.

### Interpretation caution

APR severity and risk fields are classification dimensions. Use them to describe resource intensity and mix, not to make individual clinical predictions.

## 10. Dashboard 7 - Facility & Geography

**Owner:** Mohamed Abd El Qader  
**Purpose:** locate demand, cost, and data-quality hotspots.

**Status:** built. Charts: top 10 counties by discharges and by cost, discharges by regional office, top 10 facilities by discharges and by charges, and the facility map. Data-quality cards: no open date, no location, opened after the data period, and no facility record. The facility-type matrix and the main-site check were dropped.

### Build steps

1. Rename the page `07 Facility and Geography`.
2. Add a county bar chart with `[Total Discharges]` and a separate chart with `[Total Costs]`.
3. Add a Regional Office matrix with `[Total Discharges]`, `[Average Cost per Discharge]`, and `[Average LOS]`.
4. Add a facility-type comparison with volume, LOS, and cost.
5. Add a map:
   - Latitude: `Facility_Latitude`
   - Longitude: `Facility_Longitude`
   - Size: `[Total Discharges]`
   - Tooltips: `[Average Cost per Discharge]`, `[Average LOS]`, Facility Name.
6. Add Top 10 facilities by `[Total Charges]` and a separate Top 10 by `[Total Discharges]`.
7. Add a comparison by `Main_Site_Name` or main/affiliated site fields, checking whether the relationships produce duplicate counts.
8. Add cards for:
   - Facilities with `Is_Open_Date_Missing = TRUE`
   - Facilities with `Is_Location_Missing = TRUE`
   - Facilities with `Opened_After_Data_Period = TRUE`.

### Interpretation caution

A facility with high total cost may simply have high volume. Always show volume beside total cost and average cost.

## 11. Dashboard 8 - Ownership, Operators & Cost Transparency

**Owner:** Mohamed Abd El Qader  
**Purpose:** add organizational context and comparable-case price benchmarking.

**Status:** partial. The supported half is built (see below). The cost-transparency half is not, and the page has a note saying so.

### Current-model version

Until `Fact_CostTransparency` is added, build the supported portion:

1. Rename the page `08 Ownership and Operators`.
2. Add a bar chart of `Ownership_Type` by facility count.
3. Add operator ranking by facility count.
4. Add operator comparison by `[Total Discharges]`, `[Total Costs]`, `[Average Cost per Discharge]`, and `[Average LOS]`.
5. Add cooperator ranking by number of linked facilities.
6. Add a facility matrix with operator, ownership, facility count, discharges, cost, and LOS.

### Required model extension for full plan

Load `Fact_CostTransparency` with at least:

- Facility key.
- APR-DRG key.
- Severity key.
- Year key.
- Mean Charge and Median Charge.
- Mean Cost and Median Cost.

Then create:

```DAX
Charge Median-Mean Gap =
[Mean Charge] - [Median Charge]

Transparency Markup =
DIVIDE ( [Mean Charge] - [Mean Cost], [Mean Cost] )
```

Build:

- Mean versus median charge by APR-DRG.
- Mean versus median cost by APR-DRG.
- Ownership comparison.
- Operator and cooperator facility counts.
- Same APR-DRG/severity facility price variation.
- Year trend for the top five APR-DRGs.
- Highest markup facilities, with minimum case/record-volume filters.

Do not recreate transparency metrics from `Fact_Discharges`; discharge totals are not equivalent to mean/median benchmark records.

## 12. Dashboard 9 - Neonatal & Birth Weight

**Owner:** Taqeyy  
**Purpose:** isolate a high-priority cohort and compare its operational intensity.

**Status:** partial. Cards for neonatal discharges, share, average LOS, average cost and expired share. Charts: neonatal volume and share by year, neonates vs. others on LOS and on cost vs. charge, top facilities, severity, and primary payer. Mortality is a card rather than a by-year chart. There is no birth-weight view, and the page has a note saying so.

### Current-model version

1. Rename the page `09 Neonatal Care`.
2. Add cards for `[Neonatal Discharges]` and `[Neonatal Share]`.
3. Add a Year chart of neonatal count and share.
4. Add a neonate versus non-neonate comparison for `[Average LOS]`, `[Average Cost per Discharge]`, and `[Average Charge per Discharge]`.
5. Add a facility chart for neonatal volume and a separate chart for average neonatal cost.
6. Add neonatal diagnosis by volume.
7. Add severity/risk mix filtered by `IsNeonate = TRUE`.
8. Add payment typology and patient disposition charts filtered to neonates.
9. Add neonatal mortality share by Year.

### Required model extension for full plan

Restore `BirthWeight` in the `gold Fact_Discharges` Power Query expression and refresh. Then create a birth-weight band calculated column or Power Query column:

- Under 1,500 g.
- 1,500-2,499 g.
- 2,500 g and above.
- Unknown/missing, if applicable.

Add a birth-weight distribution chart and a scatter plot with BirthWeight on X, average LOS or TotalCosts on Y, and discharge count as size. Add a tooltip with severity and diagnosis.

### Interpretation caution

Neonatal comparisons are cohort comparisons. Do not call them causal effects of birth weight without clinical validation.

## 13. Dashboard 10 - Trends, Growth & Forecasting

**Owner:** Taqeyy  
**Purpose:** close the report with change over time and cautious planning signals.

**Status:** built as scenarios, not a forecast. Cards for discharges, charges and costs vs. prior year and the LOS change, plus scenario cards (next-year discharges flat, discharges if growth repeats, costs if growth repeats). Charts: discharges, charges/costs, average LOS and average cost per discharge by year, payer mix by year, a top-10 diagnosis table by year, and a facility change table (100+ discharges). Cost-to-charge ratio by year was not added.

### Build steps

1. Rename the page `10 Trends and Forecasting`.
2. Add KPI cards for `[Discharges YoY %]`, `[Charges YoY %]`, `[Costs YoY %]`, and the change in `[Average LOS]`.
3. Add a line chart by Year for total discharges, charges, and costs. Use separate charts if scales conflict.
4. Add a facility table with current-year discharges, prior-year discharges, and YoY percentage. Sort by absolute change and apply a minimum-volume filter.
5. Add diagnosis comparison using Year as legend and diagnosis as axis; keep to Top 10 or use small multiples.
6. Add Year charts for average LOS, average cost per discharge, and cost-to-charge ratio.
7. Add a 100% stacked area or column chart for payment mix by year.
8. For forecasting:
   - Use the Analytics pane on a time series with a genuinely time-granular date field if available.
   - The model has four annual points (2018-2021) and Year is not a date field, so the page uses scenario cards instead of the Analytics-pane forecast.
   - Show the forecast interval and state that it is not a clinical or financial commitment.

### Interpretation caution

Four annual points are not enough to establish seasonality or a long-term trend, and 2020 sits inside the pandemic dip, so growth into 2021 partly reflects a recovery. The scenario cards repeat the latest year-over-year change for one more year. Treat them as a planning prompt, not a prediction.

## 14. QA checklist before merging pages

### Model and refresh

- Refresh succeeds.
- No unexpected duplicate relationships or many-to-many ambiguity.
- Year filters affect all intended visuals.
- Facility filters affect all intended visuals.
- Unknown/missing categories are visible or documented.

### Measure correctness

- Counts use `COUNTROWS` or the discharge key at the intended grain.
- Total costs and charges use `SUM`.
- Average cost and LOS use averages or explicit ratios as appropriate.
- Ratios are not summed.
- YoY measures return blank rather than a misleading value when the prior year is absent.

### Visual correctness

- Every chart has a clear title and unit.
- Top N filters use the intended measure.
- High averages with tiny sample sizes are flagged.
- Tooltips include volume alongside cost/LOS.
- Slicers are tested in at least two combinations.
- Cross-highlighting does not create an obviously incorrect denominator.

### Story correctness

- The page answers the assigned questions without claiming causality.
- The page has a clear transition to the next owner's pages.
- The page includes one or two operational implications, not a list of unrelated observations.
- Findings are based on refreshed values, not assumptions from the plan.

### Checks on first open

1. Refresh succeeds, and the row count of `gold Fact_Discharges` is recorded.
2. The map on page 7 shows bubbles. If not, re-drag Latitude and Longitude.
3. `Unmapped Facility Discharges` is not zero and matches the blank regional-office row.
4. The "Expired" disposition and severity code 4 (Extreme) both return non-zero counts.
5. Each page is spot-checked at two slicer combinations, and card text is not clipped on your screen.

## 15. Suggested handoff protocol for the five contributors

1. Hamza creates the shared measures, theme, slicer style, and landing-page layout first.
2. Each contributor builds two pages using the same model and naming convention.
3. Each contributor records:
   - Three headline findings.
   - One limitation or data-quality note.
   - The exact filters used for each headline finding.
   - One sentence transitioning to the next contributor.
4. The team performs one joint refresh and visual QA pass.
5. The team replaces placeholders in the presentation story with validated numbers.
6. The team decides whether to add `Fact_CostTransparency` and restore `BirthWeight` before presenting the corresponding questions as complete.

