# PHQ-9 Depression Severity and All-Cause Mortality
### Survey weighted Cox analysis of NHANES

## Status
Plumbing phase - building the reproducable pipeline (svydesign object, LMF linkage). Analysis and write-up to follow.
**Plumbing validated (13 Aug 2026)**: the full pipeline reproduces a published NCHS benchmark exactly. Applying the survey design and PHQ-9 scoring to NHANES 2013-2016 (ages 20+) yields 8.1% weighted prevalence of PHQ-9 >=10, matching Brody, Pratt & Hughes (2018), NCHS Data Brief No. 303, to the reported decimal. See `R/07_validation.R`.
## Research question
Does PHQ-9 defined depression severity predict all-cause mortality in the US adult population, after accounting for the complex NHANES survey design?

## Data
- NHANES demographic, questionnaire (PHQ-9), and MEC exam data --- Accessed via the R package `nhanesA`
- NCHS Public-Use Linked Mortality File (LMF) --- fixed width, joined on `SEQN`

**Cycle Range**: 2005-2006 through 2017-2018 (seven NHANES cycles). The range is bounded on both ends: PHQ-9 (`DPQ`) was first added to NHANES in the 2005-2006 cycle, and the public-use Linked Mortality File currently covers cycles only thorugh 2017-2018 (follow-up through December 31, 2019). Pooling all seven maximizes death events for statistical power; the tradeoff is the uneven follow-up length across cohorts (~13 years for 2005-2006 vs. ~1-2 years for 2017-2018), which the Cox model accomodates natively through censoring rather than requiring equal follow-up per person.

**Linkage & eligibility**: Pooling all seven cycles gives out 70,190 respondans. Out of those, 42,022 (~60%) were mortality-linkage eligible (`ELIGSTAT==1`); 28,168 were excluded because they were either under 18 at the time of the exam (mortality data is not released for minors) or had insufficient identifying information for NCHS to attempt linkage to the National Death Index. The eligible cohort (n=42,022) is the analytic sample carried forward into the survey design and Cox model.

**Data is not included in this repository.** The LMF's NCHS data-use terms prohibit redistribution. To reproduce:
1. `R/01_download_data.R` pulls NHANES data directly via `nhanesA`
2. Request the LMF from NCHS and place it in `data/raw`

**PHQ-9 scoring**: Complete-case scoring, meaning all 9 items must be answered, if any single missing item exists the total score per entry is set to NA rather than prorating. `DPQ100` (a difficulty follow-up question) is excluded, as it is not part of the PHQ-9 instrument itself. Severity bands follow the standard PHQ-9 cutiffs: Minimal (0-4), Mild (5-9), Moderate (10-14), Moderately severe (15-19), Severe (20-27). Pooled across seven cycles, the distribution is strongly right-skewed (67.5% minimal, 0.8% severe), consistent with published PHQ-9 distributions in general (non-clinical) population samples.

**Survey design**: `svydesign` uses the MEC exam weight (`WTMEC2YR`), divided by 7 to account for pooling seven cycles. I went with `WTMEC2YR` because PHQ-9 was collected during the MEC exam, not the interview. Before combining cycles, `SDMVSTRA` was confirmed to be globally unique across all seven cycles (thankfully no stratum-number was reused between cycles), so cycles could be pooled directly without constructing a combined cycle+stratum identifier. The resulting design has 214 clusters, consistent with NCHS's standard masked-variance convention of ~2 PSUs per stratum (101 strata with 2 PSUs, 4 strata with 3, confirmed directly against the data).

NCHS's own documentation for each DPQ data file confirms this directly: "Mobile Examination Center (MEC) participants... were eligible" for the depression screener, and states that "The NHANES full sample 2-Year MEC Exam Weights (WTMEC2YR) should be used to analyze these data" (e.g. https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2005/DataFiles/DPQ_E.htm).
## Reproducing this analysis
```bash
git clone <repo-url>
cd nhanes-phq9-mortality
R -e "renv::restore()"
quarto render reports/analysis.qmd
```
## Method (brief)
- **Survey design**: `svydesign`, combining NHANES cycles with MEC exam weights divided across the number of pooled cycles
- **Exposure**: PHQ-9 severity category
- **Outcome**: survey-weighted Cox proportional hazards (`svycoxph`, `survey`, package)
- **Sensitivity**: propensity-score-weighted model (secondary, optional --- not a part of the core scope)

##License
MIT
