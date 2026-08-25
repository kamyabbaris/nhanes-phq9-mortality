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

## Results

**Adjusted Cox proportional hazards model** (n = 22,471; 2,108 deaths), PHQ-9 severity vs. all-cause mortality, adjusted for age (stratified — see Proportional Hazards Check below), sex, race/ethnicity, education, marital status, income ratio, BMI, smoking status, diabetes, and CVD:

| PHQ-9 category (vs. Minimal) | HR | 95% CI | p |
|---|---|---|---|
| Mild (5–9) | 1.22 | 1.05–1.41 | 0.007 |
| Moderate (10–14) | 1.31 | 1.02–1.68 | 0.032 |
| Moderately severe (15–19) | 1.76 | 1.19–2.58 | 0.004 |
| Severe (20–27) | 1.19 | 0.59–2.42 | 0.601 |

A clear, largely monotonic dose-response can be seen from Mild through Moderately severe. The Severe category's lower point estimate and loss of significance is most likely due to the small sample size (n= 337 in the raw data, before further restriction with covariate-completeness) rather than a genuine reversal of the trend. The confidence interval in the Severe category is nearly twice as wide as Moderately severe's, consistent with an underpowered subgroup rather than a true ceiling effect. 

Full model output: `docs/cox_model_hr_table.html`. See `R/11_cox_model.R`.

**Note**: svycoxph() requires explicit exclusion of zero-weight rows before fitting (a documented package-level requirement, not specific to this dataset). For more, see script comments.

**Proportional hazards check**: `cox.zph()` on the survey-weighted model produced odd results (chi-square values near zero, p ~1 for every covariate). `cox.zph()` is documented and tested against plain `coxph()` fits rather than `svycoxph()`, I assume this is the reason. As a workaround to my case, I made a parallel `coxph()` model that fits the same complete-case data, using case weights normalized to the real sample size (not raw survey weights, `coxph()` misinterpreted them as literal row-duplication counts). This diagnostic-only model found a clear violation for age (X^2=27.5, p<0.001), and weaker violations for sex (p=0.009) and CVD (p=0.037); PHQ-9 category itself showed no evidence of violation (p=0.29).

Age was then stratified (`strata(age_group)`, four bands) in a refit of the primary model, since its violation was by far the largest and a stratified variable no longer requires an assumed-constant hazard ratio. Sex and CVD's more modest violations are noted as a limitation rather than remedied, to avoid over-fragmenting the model's risk sets. The headline PHQ-9 hazard ratios are materially unchanged after this correction (Moderately severe: 1.64 -> 1.76), indicating the primary finding is not sensitive to this modeling choice. 

See `R/12_cox_ph_check.R`; final model: `docs/cox_model_v2_hr_table.html`.
### Sensitivity analysis: propensity-score weighting vs. direct adjustment

As a robustness check, PHQ-9 was collapsed to a binary "depression" exposure (score ≥ 10, matching the threshold validated against NCHS Data Brief 303) and compared under two different confounding-adjustment strategies:

| Method | HR | 95% CI | p |
|---|---|---|---|
| Direct adjustment (covariates in model) | 1.31 | 1.07–1.60 | 0.009 |
| Propensity-score weighting (IPTW, trimmed at 99th percentile) | 1.25 | 0.99–1.58 | 0.060 |

The two estimates are directionally consistent with substantially overlapping confidence intervals, supporting the robustness of the primary finding to the choice of confounding-adjustment method. The propensity-weighted estimate's borderline significance (CI lower bound 0.99) is consistent with IPTW's known lower statistical efficiency relative to direct adjustment, rather than a genuine disagreement between methods.

See `R/13_sensitivity_propensity.R`.

##License
MIT
