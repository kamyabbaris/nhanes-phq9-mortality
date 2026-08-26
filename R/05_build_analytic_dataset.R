# Merge mortality-linked data, PHQ-9 scores, and covariates into one analytic frame
# Standardize inconsistent factor labels across cycles; declare explicit factor levels

library(dplyr)

eligible_data <- readRDS("data/processed/nhanes_mortality_linked.rds")
phq9_all <- readRDS("data/processed/phq9_scored.rds")
covariates_all <- readRDS("data/processed/covariates_all.rds")

analytic_data <- eligible_data %>%
  left_join(select(phq9_all, SEQN, phq9_score, phq9_category), by = "SEQN") %>%
  left_join(select(covariates_all, -cycle), by = "SEQN")

# Education: standardize capitalization inconsistencies across cycles before declaring levels
educ_map <- c(
  "Less Than 9th Grade" = "Less than 9th grade", "Less than 9th grade" = "Less than 9th grade",
  "9-11th Grade (Includes 12th grade with no diploma)" = "9-11th grade (Includes 12th grade with no diploma)",
  "9-11th grade (Includes 12th grade with no diploma)" = "9-11th grade (Includes 12th grade with no diploma)",
  "High School Grad/GED or Equivalent" = "High school graduate/GED or equivalent",
  "High school graduate/GED or equivalent" = "High school graduate/GED or equivalent",
  "Some College or AA degree" = "Some college or AA degree", "Some college or AA degree" = "Some college or AA degree",
  "College Graduate or above" = "College graduate or above", "College graduate or above" = "College graduate or above",
  "Refused" = NA, "Don't Know" = NA, "Don't know" = NA
)
analytic_data$education <- factor(
  educ_map[as.character(analytic_data$DMDEDUC2)],
  levels = c("Less than 9th grade", "9-11th grade (Includes 12th grade with no diploma)",
             "High school graduate/GED or equivalent", "Some college or AA degree",
             "College graduate or above")
)

# Marital status: same standardization
marital_map <- c("Married" = "Married", "Widowed" = "Widowed", "Divorced" = "Divorced",
                  "Separated" = "Separated", "Never married" = "Never married",
                  "Living with partner" = "Living with partner",
                  "Refused" = NA, "Don't know" = NA, "Don't Know" = NA)
analytic_data$marital_status <- factor(
  marital_map[as.character(analytic_data$DMDMARTL)],
  levels = c("Married", "Widowed", "Divorced", "Separated", "Never married", "Living with partner")
)

# Sex, race/ethnicity, smoking: explicit levels (Non-Hispanic White as reference)
analytic_data$sex <- factor(analytic_data$RIAGENDR, levels = c("Male", "Female"))
analytic_data$race_ethnicity <- factor(
  analytic_data$RIDRETH1,
  levels = c("Non-Hispanic White", "Non-Hispanic Black", "Mexican American",
             "Other Hispanic", "Other Race - Including Multi-Racial")
)
analytic_data$smoking_status <- factor(analytic_data$smoking_status, levels = c("never", "former", "current"))

final_data <- analytic_data %>%
  transmute(
    SEQN, cycle, age = RIDAGEYR, sex, race_ethnicity, education, marital_status,
    income_ratio = INDFMPIR, bmi = BMXBMI_clean, smoking_status, diabetes, cvd,
    phq9_score, phq9_category,
    wt_int = WTINT2YR, wt_mec = WTMEC2YR, psu = SDMVPSU, strata = SDMVSTRA,
    mortstat, permth_exm, ucod_leading
  )

dir.create("data/derived", showWarnings = FALSE, recursive = TRUE)
saveRDS(final_data, "data/derived/analytic_dataset.rds")

cat("Final analytic dataset:", nrow(final_data), "rows,", ncol(final_data), "columns\n")

