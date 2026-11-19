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

The source material identifies the data as New York SPARCS de-identified inpatient discharges. The planning documents say 2022 and 2023, but the refreshed model holds four years, 2018-2021, so use the years and values from the refresh. The PBIP semantic model contains:

- One main fact table: `gold Fact_Discharges`.
- Dimensions for year, facility, patient, admission, payment, diagnosis, procedure, APR-DRG, APR-MDC, severity, and medical/surgical classification.
- Operator and cooperator dimensions connected to facilities through bridge tables.
- Financial fields: `TotalCharges`, `TotalCosts`, `CostToChargeRatio`, and `CostChargeDifference`.
- Operational fields: `LengthOfStay`, `HasProcedure`, `HasSecondaryInsurance`, `IsNeonate`, and admission/disposition fields.

The presentation should use exact values from the refreshed Power BI model. Do not invent headline numbers from the plan document; the project files hold the model and report definitions, not final numbers.

### Where the build stands

All ten pages are built, on a 1280x720 canvas with the same layout: a header with the decision question, a left filter rail (Year, Facility type, County plus one page-specific slicer), a KPI row, two rows of charts, and a footer. The model has 66 measures in nine folders. Pages 8 and 9 are the two partial ones.

### Current model gaps that must be disclosed

1. **Cost transparency is not currently loaded.**  
   The plan references `Fact_CostTransparency`, but no corresponding semantic-model table definition is present. Dashboard 8 can use operator, cooperator, facility, and discharge financial fields, but its mean-versus-median transparency questions require that table to be added.
2. **Birth weight is not currently available in the fact table.**  
   The Power Query expression for `gold Fact_Discharges` explicitly removes `BirthWeight`, and no `BirthWeight` column is exposed. Dashboard 9 can analyze `IsNeonate`, but birth-weight bands and birth-weight-versus-cost/LOS questions require restoring the column.
3. **Some discharges have no facility record.**  
   They fall into a blank regional-office group and are left out of facility rankings. A card on the facility page, `Unmapped Facility Discharges`, counts them. Say so whenever facility or regional numbers are shown, because those totals will not add up to the system total.
4. **The model uses imported data from SQL Server.**  
   Each contributor should refresh the model before validating numbers and should use the shared model rather than separate extracts.
5. **Operator counts double count.**  
   A facility with two operators appears under each, so operator rows do not sum to the total. Facility, operator and cooperator counts only include facilities that have discharges.

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
| Add ownership and benchmark context | 8. Ownership, Operators & Cost Transparency | Mohamed Abd El Qader | Compares ownership and operator context on volume, cost and stay. The price-variation view is not built because the table is missing, and the page says so. |
| Tell the vulnerable-population story | 9. Neonatal & Birth Weight | Taqeyy | Shows neonatal volume, outcomes, cost, severity, and payer context; the birth-weight views are not built because the field is missing, and the page says so. |
| Close with change and action | 10. Trends, Growth & Forecasting | Taqeyy | Shows year-over-year movement, mix changes, facility/diagnosis growth, and scenario cards for the next period (flat, and latest growth repeated). |

### Linking the dashboards: the handover map

Each dashboard ends by handing the audience a question that the next dashboard answers. The table shows what is handed over at every link, who says it, and what carries across on screen. The spoken bridge line for each link is in section 4, at the end of the block it closes.

| Link | Speaker | What the audience has just seen | Question handed to the next page | What carries across |
|---|---|---|---|---|
| Opening to 1 | Hamza | The decision problem and the five questions | How large is the inpatient system? | The five questions from section 1 act as the agenda for the whole talk. |
| 1 to 2 | Hamza | Scale: discharges, charges, costs, average LOS, year comparison | How much of that scale is money, and is a charge the same as a cost? | Same Year selection. The charges and costs totals on page 1 become the cards on page 2. |
| 2 to 3 | Hamza to Seif el deen | Charges versus costs, and where the gap and the cost per case are highest | Is the cost pressure about price, or about how long patients occupy beds? | Average cost per discharge on page 2 links to the LOS-versus-cost view on page 3. |
| 3 to 4 | Seif el deen | Admission pathways, LOS bands, dispositions and the long-stay groups | Who are the patients behind these flows, and who pays for their care? | Admission type on page 3 becomes age group and primary payer on page 4. |
| 4 to 5 | Seif el deen to Mohamed Rashed | Who uses the system, where they come from and how payer mix differs | Which conditions and procedures sit behind these volumes? | Age group appears on pages 4 and 5 but is not synced, so set it again on page 5 if it was filtered. |
| 5 to 6 | Mohamed Rashed | Top diagnoses and procedures by volume, total cost and cost per case | Why do some cohorts use more resources: what clinical complexity is behind it? | The total-cost decomposition tree on page 5 leads to cost and LOS by severity on page 6. |
| 6 to 7 | Mohamed Rashed to Mohamed Abd El Qader | The severity gradient, risk of mortality, top APR-DRGs and MDCs, medical versus surgical | Where is this burden located? | Severity mix on page 6 becomes "busy versus high-burden" sites on page 7. |
| 7 to 8 | Mohamed Abd El Qader | Hotspots by county, region and facility, plus the data-quality cards | Do ownership and operator context help explain the differences between sites? | Facility type and county filters stay on. The facility list on page 7 leads to operators and ownership on page 8. |
| 8 to 9 | Mohamed Abd El Qader to Taqeyy | Operator and ownership comparisons; the price benchmark is not built | Is there a small, high-intensity cohort that the all-discharge averages hide? | Same Year, Facility type and County filters. Facility concentration on page 7 leads to neonatal facility concentration on page 9. |
| 9 to 10 | Taqeyy | The neonatal cohort: volume, LOS, cost, severity and payer mix | How stable are these patterns over time, and what should we plan for? | Clear the Year slicer first, so the trend charts on page 10 show all four years. |
| 10 to synthesis | Taqeyy to Hamza or the team | Year-over-year change and the scenario cards | What do the ten pages tell us together, and what should we do? | Return to page 1 with the filters cleared, so the headline numbers can be restated. |

#### How the filter context carries from page to page

- The **Year**, **Facility type** and **County** slicers are synced across all ten pages. Set them once on page 1 and the next page opens with the same selection. **Regional office** is synced on pages 1, 7 and 10 only.
- The page-specific slicers (payment type, admission type, age group, medical/surgical, ownership type, severity) are not synced. Reset them when you move on if the next page looks unexpectedly filtered.
- The pages sit in story order in the report, 1 to 10, so the tabs can be clicked left to right. The report has no navigation buttons.
- Start the walkthrough with Year, Facility type and County cleared. Change them only on purpose, and say out loud when you do.

## 4. Recommended presentation sequence and timing

The order below is optimized for a 10-15 minute presentation, not for dashboard-number order alone.

Each block ends with a **Transition** line: the sentence that closes the current dashboard and opens the next one. A transition takes about 10-15 seconds and is spoken inside the block it closes, so the timings below do not change. Where the speaker changes, the transition names both people. The incoming speaker then opens by reading the page header's decision question aloud, before the first number, so the audience hears how the new page answers the question just handed over.

### 0:00-0:45 - Opening: the decision problem

**Speaker:** Hamza  
Introduce CareLens as an operational decision-support view for inpatient discharges. State that the project answers: *How much demand exists, where is it concentrated, what makes it expensive or capacity-intensive, and what should managers investigate next?*

**Transition to Dashboard 1:** "Everything we show is one story told across ten pages, and it starts with the size of the system."

### 0:45-2:00 - Establish the baseline

**Speaker:** Hamza, Dashboard 1  
Show total discharges, total charges, total costs, average cost per discharge, average LOS, and the year comparison. Mention emergency, procedure, neonatal, and top-facility shares as context.

**Transition to Dashboard 2:** "The total is only the starting point. We now need to separate operating volume from financial pressure."

### 2:00-3:00 - Financial pressure

**Speaker:** Hamza, Dashboard 2  
Use one charges-versus-costs trend and one facility/diagnosis outlier view. Explain that a high charge is not automatically a high cost and that the cost-to-charge ratio is a benchmarking signal, not a quality score.

**Transition to Dashboard 3 (Hamza to Seif el deen):** "Now that we know the size and money involved, we need to understand the patient flow creating that burden." Hamza then hands over to Seif el deen.

### 3:00-4:15 - Patient flow and capacity

**Speaker:** Seif el deen, Dashboard 3  
Show admission type, LOS distribution, disposition, emergency versus non-emergency LOS, and the LOS-cost relationship. Emphasize that longer-stay cohorts create bed-day pressure even when their discharge count is not the largest.

**Transition to Dashboard 4:** "The system burden is shaped not only by how many patients arrive, but by how long they stay and by the population and payer mix."

### 4:15-5:15 - Population and payer context

**Speaker:** Seif el deen, Dashboard 4  
Show age, gender/race/ethnicity, payment mix, secondary insurance, and geographic origin. Use this to explain who is behind the aggregate demand and how payer mix can affect financial interpretation.

**Transition to Dashboard 5 (Seif el deen to Mohamed Rashed):** "We now know who the patients are and who pays. The next question is what they are being treated for: which conditions and procedures sit behind these volumes." Seif el deen then hands over to Mohamed Rashed.

### 5:15-6:30 - Clinical demand drivers

**Speaker:** Mohamed Rashed, Dashboard 5  
Show the top diagnoses and procedures by volume, cost, average cost, and LOS. Use the decomposition tree to drill into total cost. Avoid naming a "worst" diagnosis; call it a high-volume or high-resource cohort.

**Transition to Dashboard 6:** "The top-line volume becomes meaningful when we separate common cases from resource-intensive cases and then view them through clinical complexity."

### 6:30-7:45 - Complexity and risk

**Speaker:** Mohamed Rashed, Dashboard 6  
Show severity and risk-of-mortality distributions, the cost/LOS gradient by severity, top APR-DRGs/MDCs, and medical versus surgical differences. This is the explanation layer for why the demand drivers do not all have the same operational impact.

**Transition to Dashboard 7 (Mohamed Rashed to Mohamed Abd El Qader):** "Once we know what creates the burden, we can locate it and identify the organizational contexts where intervention may be practical." Mohamed Rashed then hands over to Mohamed Abd El Qader.

### 7:45-9:00 - Geographic and facility hotspots

**Speaker:** Mohamed Abd El Qader, Dashboard 7  
Use the map and ranked facility/county/region views to locate concentration. Compare volume with average cost and LOS so the audience can distinguish "busy" from "high-burden."

**Transition to Dashboard 8:** "Knowing which sites are busy, expensive or long-stay raises the next question: does who owns or operates a site help explain the difference?"

### 9:00-10:00 - Ownership and benchmark context

**Speaker:** Mohamed Abd El Qader, Dashboard 8  
Compare ownership and operator context on discharges, cost and stay. `Fact_CostTransparency` is not in the model, so show the operator and ownership comparisons that are built and state that comparable-case mean/median price benchmarking is a planned model extension.

**Transition to Dashboard 9 (Mohamed Abd El Qader to Taqeyy):** "Ownership and operator context describe all discharges together, and averages across everyone can hide a small, high-intensity group. The next page isolates one: neonatal care." Mohamed Abd El Qader then hands over to Taqeyy.

### 10:00-11:15 - Neonatal priority cohort

**Speaker:** Taqeyy, Dashboard 9  
Show neonatal share, the LOS and cost comparison with other discharges, facility concentration, severity, payment mix, and the expired share card. Birth weight is not in the model, so there are no weight-band or scatter views. Say that out loud instead of leaving a gap. Neonatal diagnosis and disposition are not separate charts.

**Transition to Dashboard 10:** "A priority cohort is a snapshot. The last question is how stable these patterns are over time, and what the next period might look like." Clear the Year slicer before moving on.

### 11:15-12:30 - What changed and what comes next

**Speaker:** Taqeyy, Dashboard 10  
Show YoY changes, payment mix by year, the facility change table and the scenario cards. The scenarios repeat the latest growth for one more year, and the latest year follows the 2020 pandemic dip, so some of that growth is recovery. Do not present them as a forecast.

**Transition to the synthesis (Taqeyy to Hamza or the team):** "The dashboard does not replace operational judgment; it identifies the cohorts and sites where the next question, intervention, or resource decision should be focused. Here is what the ten pages tell us together." Return to page 1 with the filters cleared.

### 12:30-14:00 - Synthesis and recommendations

**Speaker:** Hamza or the whole team  
Summarize the three to five strongest observed patterns from the completed refresh. Then state the actions below, using the actual dashboard evidence to replace the bracketed prompts.

**Transition to the limitations:** "Before we close, here is what these dashboards cannot tell us, and the two model extensions that would complete the picture."

### 14:00-15:00 - Limitations and close

Mention de-identification, observational association, the four-year window (2018-2021) with 2020 inside the pandemic dip, imported-model refresh dependency, discharges with no facility record, operators counted under each of a facility's operators, the missing transparency table, the removed birth-weight field, and the need for validation with clinical and finance stakeholders.

## 5. What each person should say and deliver

### Hamza - Dashboards 1 and 2: "Scale and money"

Hamza owns the opening and the financial frame. His contribution is to answer:

- How large is the inpatient system?
- Is volume growing or falling?
- How much is charged versus how much it costs?
- Which facilities, diagnoses, or payer groups create the largest financial concentration?

His transition should be: **"Now that we know the size and money involved, we need to understand the patient flow creating that burden."**

**Hand-over:** opens the talk; hands over to Seif el deen after Dashboard 2; takes the synthesis back after Dashboard 10.

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

**Hand-over:** receives the cost-per-case and facility-type cost picture from Hamza; hands over to Mohamed Rashed after Dashboard 4 with the question of what the patients are treated for.

He should avoid implying that race, ethnicity, or payment causes cost differences. Present them as descriptive stratifications.

### Mohamed Rashed - Dashboards 5 and 6: "Demand drivers and complexity"

Mohamed Rashed owns the clinical explanation layer. His contribution is to answer:

- Which diagnoses and procedures create the most volume?
- Which are high-cost or high-LOS despite lower volume?
- How does severity and risk change cost and LOS?
- Which MDCs or APR-DRGs should receive operational attention?

His transition should be: **"The top-line volume becomes meaningful when we separate common cases from resource-intensive cases and then view them through clinical complexity."**

**Hand-over:** receives the population and payer mix from Seif el deen; hands over to Mohamed Abd El Qader after Dashboard 6 with the question of where the burden sits.

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

**Hand-over:** receives the severity and demand-driver picture from Mohamed Rashed; hands over to Taqeyy after Dashboard 8 with the question of which small cohort the averages hide.

The transparency table is not in the model, and the page says so. Do not simulate mean/median transparency results from discharge totals. Remind the audience that operator rows do not sum to the total.

### Taqeyy - Dashboards 9 and 10: "Priority cohort and change"

Taqeyy owns the vulnerable-population and forward-looking close. Her contribution is to answer:

- Is neonatal care a small-volume but high-intensity cohort?
- Which facilities, severity levels, and payers characterize neonatal care?
- What changed between years?
- Which patterns are stable enough to inform near-term planning?

Her close should be: **"The dashboard does not replace operational judgment; it identifies the cohorts and sites where the next question, intervention, or resource decision should be focused."**

**Hand-over:** receives the facility and ownership context from Mohamed Abd El Qader; hands back to Hamza or the team for the synthesis.

The forward-looking cards are scenarios, not forecasts: there are four years of data and 2020 sits inside the pandemic dip.

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
- Open every page by reading its decision question aloud, and close it with the transition line from section 4, so each dashboard visibly hands over to the next.
- Do not change the synced slicers between pages without saying so. Clear the Year slicer before the trend page.
- Every page should have one sentence at the top stating the decision question.
- Keep each page to a few purposeful visuals. The built pages run to about six to eight charts and tables beside the slicer rail, and several planned charts were folded into tooltips or dropped.
- Use the same colors throughout: volume teal, costs navy, charges slate, LOS amber, neonatal violet.
- Put units in titles: currency, days, percentage, or discharge count.
- Rank only groups with at least 100 discharges (the `Ranked ...` measures do this) before calling a facility or diagnosis an outlier. Scatter plots only use sites with 1,000+ discharges.
- Use tooltips to show count, average cost, average LOS, and share together.
- Never infer clinical quality, mortality causation, profitability, or patient-level behavior from these aggregate, de-identified data alone.

