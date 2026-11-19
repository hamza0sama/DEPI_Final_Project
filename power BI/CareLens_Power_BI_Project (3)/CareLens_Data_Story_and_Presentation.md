# CareLens: Data Story and 10-15 Minute Presentation Plan

## 1. The big picture

CareLens should not be presented as ten unrelated dashboards. It should be presented as one operational story about **where hospital demand comes from, which patients and clinical groups create the greatest pressure, how that pressure affects capacity and cost, and where managers should focus resources**.

The recommended narrative is:

> **Healthcare demand is not evenly distributed.** It is concentrated in particular years, places, patient groups, admission pathways, diagnoses, procedures, and severity levels. Those concentrations create different operational burdens: some cases consume beds because they stay longer, some consume clinical capacity because they are more severe, and some create financial pressure because charges and costs diverge. CareLens connects these views so administrators can move from "what happened?" to "where should we investigate or allocate resources?".

The presentation should move through five questions:

1. **What is the overall system load?**  
   How many discharges occurred, how did volume change, and what happened to average LOS and financial totals?
2. **Where is the load concentrated?**  
   Which facilities, counties, regions, facility types, and ownership groups carry the most activity and cost?
3. **Who and what drives the load?**  
   Which age, demographic, payment, diagnosis, procedure, MDC, APR-DRG, and medical/surgical groups dominate?
4. **Which cases create the greatest pressure?**  
   How do severity, risk of mortality, emergency admission, LOS, neonatal status, and cost interact?
5. **What should decision-makers do next?**  
   Use the dashboards to identify capacity priorities, high-cost/high-LOS cohorts, geographic gaps, and data-quality or pricing questions for follow-up.

This framing keeps the team from claiming that the dashboards prove clinical causality. They show **associations and operational patterns** in de-identified inpatient discharge data.

## 2. Scope and evidence boundaries

The source material identifies the data as New York SPARCS de-identified inpatient discharges for 2022 and 2023. The PBIP semantic model currently contains:

- One main fact table: `gold Fact_Discharges`.
- Dimensions for year, facility, patient, admission, payment, diagnosis, procedure, APR-DRG, APR-MDC, severity, and medical/surgical classification.
- Operator and cooperator dimensions connected to facilities through bridge tables.
- Financial fields: `TotalCharges`, `TotalCosts`, `CostToChargeRatio`, and `CostChargeDifference`.
- Operational fields: `LengthOfStay`, `HasProcedure`, `HasSecondaryInsurance`, `IsNeonate`, and admission/disposition fields.

The presentation should use exact values from the refreshed Power BI model. Do not invent headline numbers from the plan document; the repository contains the model definition and notebooks but not the final dashboard outputs.

### Current model gaps that must be disclosed

1. **Cost transparency is not currently loaded.**  
   The plan references `Fact_CostTransparency`, but no corresponding semantic-model table definition is present. Dashboard 8 can use operator, cooperator, facility, and discharge financial fields, but its mean-versus-median transparency questions require that table to be added.
2. **Birth weight is not currently available in the fact table.**  
   The Power Query expression for `gold Fact_Discharges` explicitly removes `BirthWeight`, and no `BirthWeight` column is exposed. Dashboard 9 can analyze `IsNeonate`, but birth-weight bands and birth-weight-versus-cost/LOS questions require restoring the column.
3. **No reusable measures or dashboard pages have been built yet.**  
   The report definition contains one blank page and the semantic model mainly contains columns. The team must build the measures and pages described in the companion implementation guide.
4. **The model uses imported data from SQL Server.**  
   Each contributor should refresh the model before validating numbers and should use the shared model rather than separate extracts.

These are not presentation failures; they are important data-product findings. The team should say that CareLens first establishes a reliable operational baseline, then identifies the two model extensions needed for full scope.

## 3. How the ten dashboards form one story

| Story stage | Dashboard | Owner | Contribution to the story |
|---|---|---|---|
| Establish the baseline | 1. Executive Overview | Hamza | Defines system scale, volume, cost, LOS, emergency/procedure/neonatal shares, and the five highest-volume facilities. |
| Explain financial pressure | 2. Cost & Charges | Hamza | Shows where charges, costs, mark-ups, and cost-per-case differences are concentrated. |
| Explain flow and capacity | 3. Length of Stay & Admission | Seif el deen | Connects admission pathway, disposition, mortality share, LOS, and cost pressure. |
| Explain the population and payer context | 4. Patient Demographics & Payment | Seif el deen | Shows who uses the system, where patients come from, and how payment mix differs across groups. |
| Identify demand drivers | 5. Diagnosis & Procedure | Mohamed Rashed | Converts overall volume into the main conditions and procedures driving demand, cost, and LOS. |
| Identify clinical complexity | 6. Severity, APR-DRG & MDC | Mohamed Rashed | Explains why some cohorts consume more resources and distinguishes medical from surgical burden. |
| Locate the operational hotspots | 7. Facility & Geography | Mohamed Abd El Qader | Maps the burden and highlights counties, regions, facility types, and facility-level outliers. |
| Add ownership and benchmark context | 8. Ownership, Operators & Cost Transparency | Mohamed Abd El Qader | Compares ownership/operator context and, if the missing table is added, price variation for comparable cases. |
| Tell the vulnerable-population story | 9. Neonatal & Birth Weight | Taqeyy | Shows neonatal volume, outcomes, cost, severity, and payer context; birth weight is conditional on restoring the field. |
| Close with change and action | 10. Trends, Growth & Forecasting | Taqeyy | Shows year-over-year movement, mix changes, facility/diagnosis growth, and a cautious next-period forecast. |

## 4. Recommended presentation sequence and timing

The order below is optimized for a 10-15 minute presentation, not for dashboard-number order alone.

### 0:00-0:45 - Opening: the decision problem

**Speaker:** Hamza  
Introduce CareLens as an operational decision-support view for inpatient discharges. State that the project answers: *How much demand exists, where is it concentrated, what makes it expensive or capacity-intensive, and what should managers investigate next?*

### 0:45-2:00 - Establish the baseline

**Speaker:** Hamza, Dashboard 1  
Show total discharges, total charges, total costs, average cost per discharge, average LOS, and the year comparison. Mention emergency, procedure, neonatal, and top-facility shares as context.

**Transition:** "The total is only the starting point. We now need to separate operating volume from financial pressure."

### 2:00-3:00 - Financial pressure

**Speaker:** Hamza, Dashboard 2  
Use one charges-versus-costs trend and one facility/diagnosis outlier view. Explain that a high charge is not automatically a high cost and that the cost-to-charge ratio is a benchmarking signal, not a quality score.

### 3:00-4:15 - Patient flow and capacity

**Speaker:** Seif el deen, Dashboard 3  
Show admission type, LOS distribution, disposition, emergency versus non-emergency LOS, and the LOS-cost relationship. Emphasize that longer-stay cohorts create bed-day pressure even when their discharge count is not the largest.

### 4:15-5:15 - Population and payer context

**Speaker:** Seif el deen, Dashboard 4  
Show age, gender/race/ethnicity, payment mix, secondary insurance, and geographic origin. Use this to explain who is behind the aggregate demand and how payer mix can affect financial interpretation.

### 5:15-6:30 - Clinical demand drivers

**Speaker:** Mohamed Rashed, Dashboard 5  
Show the top diagnoses and procedures by volume, cost, average cost, and LOS. Select one diagnosis and drill into its age/gender and procedure profile. Avoid naming a "worst" diagnosis; call it a high-volume or high-resource cohort.

### 6:30-7:45 - Complexity and risk

**Speaker:** Mohamed Rashed, Dashboard 6  
Show severity and risk-of-mortality distributions, the cost/LOS gradient by severity, top APR-DRGs/MDCs, and medical versus surgical differences. This is the explanation layer for why the demand drivers do not all have the same operational impact.

### 7:45-9:00 - Geographic and facility hotspots

**Speaker:** Mohamed Abd El Qader, Dashboard 7  
Use the map and ranked facility/county/region views to locate concentration. Compare volume with average cost and LOS so the audience can distinguish "busy" from "high-burden."

### 9:00-10:00 - Ownership and benchmark context

**Speaker:** Mohamed Abd El Qader, Dashboard 8  
Compare ownership/operator context and facility performance. If `Fact_CostTransparency` has not been added, explicitly show the available operator/facility discharge comparisons and state that comparable-case mean/median price benchmarking is a planned model extension.

### 10:00-11:15 - Neonatal priority cohort

**Speaker:** Taqeyy, Dashboard 9  
Show neonatal share, LOS/cost comparison with non-neonates, facility concentration, neonatal diagnosis/severity, payment mix, disposition, and mortality share. If birth weight is restored, add the weight-band and scatter visuals; otherwise label those visuals "not available in current model."

### 11:15-12:30 - What changed and what comes next

**Speaker:** Taqeyy, Dashboard 10  
Show YoY changes, changing payment mix, rising/falling facilities or diagnoses, and the forecast only as a planning signal. Do not present a two-year forecast as a definitive prediction.

### 12:30-14:00 - Synthesis and recommendations

**Speaker:** Hamza or the whole team  
Summarize the three to five strongest observed patterns from the completed refresh. Then state the actions below, using the actual dashboard evidence to replace the bracketed prompts.

### 14:00-15:00 - Limitations and close

Mention de-identification, observational association, two-year time horizon, imported-model refresh dependency, the missing transparency table, the removed birth-weight field, and the need for validation with clinical and finance stakeholders.

## 5. What each person should say and deliver

### Hamza - Dashboards 1 and 2: "Scale and money"

Hamza owns the opening and the financial frame. His contribution is to answer:

- How large is the inpatient system?
- Is volume growing or falling?
- How much is charged versus how much it costs?
- Which facilities, diagnoses, or payer groups create the largest financial concentration?

His transition should be: **"Now that we know the size and money involved, we need to understand the patient flow creating that burden."**

He should deliver:

- A clean overview page usable as the presentation landing page.
- A consistent set of KPI measures reused by every teammate.
- A short list of headline numbers after refresh.
- One financial caveat: charges are not the same as realized revenue, and ratio differences are not automatically evidence of poor performance.

### Seif el deen - Dashboards 3 and 4: "Flow and population"

Seif el deen owns the patient-flow and payer context. His contribution is to answer:

- Which admission pathways bring patients into the system?
- Which cohorts stay longer or have different dispositions?
- Who are the patients and who pays?
- Where do demographic or payment differences require closer operational attention?

His transition should be: **"The system burden is shaped not only by how many patients arrive, but by how long they stay and by the population and payer mix."**

He should avoid implying that race, ethnicity, or payment causes cost differences. Present them as descriptive stratifications.

### Mohamed Rashed - Dashboards 5 and 6: "Demand drivers and complexity"

Mohamed Rashed owns the clinical explanation layer. His contribution is to answer:

- Which diagnoses and procedures create the most volume?
- Which are high-cost or high-LOS despite lower volume?
- How does severity and risk change cost and LOS?
- Which MDCs or APR-DRGs should receive operational attention?

His transition should be: **"The top-line volume becomes meaningful when we separate common cases from resource-intensive cases and then view them through clinical complexity."**

He should distinguish:

- **High volume:** many discharges.
- **High resource burden:** high total cost or bed-day impact.
- **High average intensity:** high average cost or LOS per case.

### Mohamed Abd El Qader - Dashboards 7 and 8: "Where and under what operating context"

Mohamed Abd El Qader owns the location and organizational context. His contribution is to answer:

- Which counties, regions, facility types, and facilities carry the load?
- Which sites are busy versus expensive versus long-stay?
- How do operators and ownership types compare?
- Can comparable APR-DRG/severity cases be benchmarked on price?

His transition should be: **"Once we know what creates the burden, we can locate it and identify the organizational contexts where intervention may be practical."**

He must call out whether the transparency table is available. If not, do not simulate mean/median transparency results from discharge totals.

### Taqeyy - Dashboards 9 and 10: "Priority cohort and change"

Taqeyy owns the vulnerable-population and forward-looking close. Her contribution is to answer:

- Is neonatal care a small-volume but high-intensity cohort?
- Which facilities, diagnoses, severity levels, and payers characterize neonatal care?
- What changed between years?
- Which patterns are stable enough to inform near-term planning?

Her close should be: **"The dashboard does not replace operational judgment; it identifies the cohorts and sites where the next question, intervention, or resource decision should be focused."**

Forecasting should be framed as scenario support because the available period is only two years.

## 6. Final synthesis: how to turn dashboard results into a conclusion

At the end, select findings using this template:

1. **Scale:** "The system recorded `[X]` discharges, with volume changing by `[Y]%` between the available years."
2. **Concentration:** "The top `[N]` facilities/counties represented `[Z]%` of discharges or `[Z]%` of cost."
3. **Capacity:** "The highest LOS or bed-day pressure was associated with `[cohort]`, not necessarily the highest-volume group."
4. **Clinical intensity:** "`[severity/DRG/MDC]` had the strongest average cost/LOS signal."
5. **Equity/context:** "The distribution by `[age/geography/payment/demographic]` suggests `[operational implication]`; it is descriptive and needs stakeholder validation."
6. **Action:** "The first practical follow-up is `[capacity / case-management / facility review / data-quality / price benchmark]` for `[specific cohort or site]`."

The conclusion should contain no more than three main recommendations:

- **Capacity:** plan staffing, beds, discharge coordination, or specialty capability around the largest long-stay/high-severity cohorts.
- **Performance review:** investigate facilities that are high-cost or high-LOS after controlling the comparison as much as the model allows.
- **Data/product improvement:** add `Fact_CostTransparency`, restore `BirthWeight`, and validate the model with domain owners before making financial or clinical decisions.

## 7. Presentation quality rules

- Use the same Year, Facility Type, Facility County, and Facility slicer behavior on every page where applicable.
- Every page should have one sentence at the top stating the decision question.
- Prefer two or three purposeful visuals per page over filling the canvas with every proposed chart.
- Use the same colors for discharges, charges, costs, LOS, and severity throughout the report.
- Put units in titles: currency, days, percentage, or discharge count.
- Add "Top N" and minimum-volume filters before calling a facility or diagnosis an outlier.
- Use tooltips to show count, average cost, average LOS, and share together.
- Never infer clinical quality, mortality causation, profitability, or patient-level behavior from these aggregate, de-identified data alone.

