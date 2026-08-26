# Full pipeline, in order, from a clean session.
# Run with:  Rscript run_all.R
# Requires the NCHS Linked Mortality File in data/raw (see README).

scripts <- c(
  "00_setup.R",
  "01_download_data.R",
  "02_build_lmf.R",
  "03_score_phq9.R",
  "04_build_covariates.R",
  "05_build_analytic_dataset.R",
  "06_svydesign.R",
  "07_validation.R",
  "09_table1.R",
  "10_km_curves.R",
  "11_cox_model.R",
  "12_cox_ph_check.R",
  "13_sensitivity_propensity.R"
)

for (s in scripts) {
  cat("\n=====", s, "=====\n")
  source(here::here("R", s), echo = FALSE)
}

cat("\nPipeline complete.\n")
