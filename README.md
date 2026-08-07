# PHQ-9 Depression Severity and All-Cause Mortality
### Survey weighted Cox analysis of NHANES

## Status
Plumbing phase - building the reproducable pipeline (svydesign object, LMF linkage). Analysis and write-up to follow.

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
