# PHQ-9 Depression Severity and All-Cause Mortality
### Survey weighted Cox analysis of NHANES

## Status
Plumbing phase - building the reproducable pipeline (svydesign object, LMF linkage). Analysis and write-up to follow.

## Research question
Does PHQ-9 defined depression severity predict all-cause mortality in the US adult population, after accounting for the complex NHANES survey design?

## Data
- NHANES demographic, questionnaire (PHQ-9), and MEC exam data --- Accessed via the R package `nhanesA`
- NCHS Public-Use Linked Mortality File (LMF) --- fixed width, joined on `SEQN`

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
