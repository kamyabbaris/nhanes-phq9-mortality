# Analytic Dataset Data Dictionary
`data/derived/analytic_dataset.rds` — one row per mortality-linkage-eligible NHANES respondent (2005–2018), n = 42,022

| Column | Description | Source | Notes |
|---|---|---|---|
| SEQN | Respondent ID | DEMO | Join key across all NHANES files |
| cycle | NHANES cycle letter (D–J) | Derived | D=2005-06 ... J=2017-18 |
| age | Age in years at exam | DEMO (RIDAGEYR) | |
| sex | Male / Female | DEMO (RIAGENDR) | |
| race_ethnicity | 5 categories | DEMO (RIDRETH1) | Non-Hispanic White = reference level |
| education | 5 ordered levels, less to more | DEMO (DMDEDUC2) | Adults 20+ only; capitalization standardized across cycles |
| marital_status | 6 categories | DEMO (DMDMARTL) | |
| income_ratio | Income-to-poverty ratio | DEMO (INDFMPIR) | |
| bmi | Body mass index | BMX (BMXBMI) | Only kept where BMDSTATS = Complete or Height/weight-only partial |
| smoking_status | never / former / current | SMQ (SMQ020, SMQ040) | Never-smokers skip SMQ040 by survey design |
| diabetes | 0/1 | DIQ (DIQ010) | Borderline coded NA, not 0 or 1 |
| cvd | 0/1 composite | MCQ (MCQ160B–F) | Any confirmed Yes among CHF/CHD/angina/heart attack/stroke = 1 |
| phq9_score | 0-27 | DPQ, complete-case | NA if any of 9 items missing |
| phq9_category | 5 severity bands | Derived from phq9_score | Minimal/Mild/Moderate/Mod.severe/Severe |
| wt_int, wt_mec | Survey weights | DEMO | NOT YET divided by number of pooled cycles -- svydesign step |
| psu, strata | Cluster/stratum IDs | DEMO (SDMVPSU/SDMVSTRA) | For svydesign |
| mortstat | 0=alive, 1=deceased | LMF | NA if ineligible (eligstat != 1 already filtered out) |
| permth_exm | Follow-up months from exam | LMF | |
| ucod_leading | Leading cause of death | LMF | Mostly NA (only populated for decedents) |
