# CareLens - build notes

Open `Final Project.pbip` in Power BI Desktop (Developer Mode / PBIR enabled) and click **Refresh**.
SQL Server credentials are not stored in the project. Data in the model covers **2018-2021** (four years);
the planning guides mention 2022-2023, so ignore that wording and use the refreshed values.

## What changed in this version
**Problems from the screenshots, and the fix**
| Problem | Fix |
|---|---|
| Tables/matrices showed only their first column and crashed the renderer | Every table/matrix field is now explicitly active; matrix sort definitions removed |
| Slicer dropdowns cropped (Fluent theme item padding 10) | Slimmer slicer padding, 56 px tall, moved into a left filter rail |
| Text unreadable when fit to page (1920x1080 canvas, 8-9 px fonts) | Canvas is now 1280x720 with 10-12 pt text |
| Grey auto-subtitles repeating field names under every title | Subtitles switched off in the theme and on each visual |
| Smoothed lines exaggerating year-to-year moves | Straight lines (theme + per visual) |
| KPI cards rounded to "9M", "$19K" | Explicit units/precision (8.81M, $555.1bn, $19,059) |
| 17-21 visuals per page, truncated names, scrolling bar charts | 6-8 visuals per page on a fixed grid, titles carry units |
| "(Blank)" facility in rankings | Not-blank filter on facility rankings; new card counts discharges with no facility record |
| Facility/operator counts mixed the whole facility registry (370, 2,643, 5,798) with the 205 facilities that have discharges | Counts now only include facilities with discharges |
| Top-N + minimum-volume filters could leave a handful of bars | Ranking measures (`Ranked ...`) return blank below 100 discharges, so Top-N ranks only eligible rows |

**Layout system (every page):** header with the page's decision question; left rail with synced Year / Facility type / County
slicers plus one page-specific slicer and a short "how to read" note; KPI row; two rows of charts; dynamic footer.
Colour is semantic: volume teal, costs navy, charges slate, LOS amber, neonatal violet.

**Semantic model:** new measures in folder "9 Comparison and Ranking" (emergency / non-emergency LOS, Ranked Average LOS,
Ranked Average Cost per Discharge, Ranked Extreme Severity Share, Ranked Discharges Abs Change) and `Unmapped Facility Discharges`.
Rewritten: facility data-quality measures and operator/cooperator counts (TREATAS on facilities with discharges).

## Deliberate deviations from the guide
- Guide visuals consolidated into tooltips / fewer panels so pages stay readable (per the story guide's "two or three purposeful
  visuals" rule): page 4 race/ethnicity matrix and treemap, page 5 procedure-by-cost and diagnosis x procedure matrix,
  page 6 medical/surgical donut (kept as slicer), page 7 facility-type matrix and main-site check, page 9 diagnosis/disposition/mortality-by-year
  (mortality is a KPI and a tooltip).
- Page 8 cost transparency and page 9 birth weight are NOT built: `Fact_CostTransparency` is not in the model and `BirthWeight` is removed
  in the Fact_Discharges query. Both pages carry a short note. Restoring them needs the source column names.
- Page 10 shows scenarios (flat / latest growth repeats), not a statistical forecast. Year is not a date field, and 2020 is a pandemic dip.
- Scatter plots use sites with 1,000+ discharges so two tiny outliers do not squash the cluster. Narrow matrices were replaced by charts where they scrolled.
- Operator rows do not sum to the total (a facility with 2+ operators counts under each).

## Check on first open
1. Refresh succeeds; row count of `gold Fact_Discharges` recorded.
2. Map (page 7) shows bubbles; if not, re-drag Latitude/Longitude.
3. `Unmapped Facility Discharges` is non-zero (~148K seen in the old screenshots) and equals the blank regional-office row.
4. "Expired" disposition and severity code 4 (Extreme) return non-zero counts.
5. Spot-check each page at two slicer combinations; confirm card text is not clipped on your screen.
