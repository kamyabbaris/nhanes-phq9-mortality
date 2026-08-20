# Sensitivity analysis: propensity-score(IPTW) weighting vs. direct covariate adjustment
# using binary depression exposure (PHQ-9 >=10, matching the NCHS Data Brief 303 threshold
# already validated in R/07_validate_gate.R).
#
# Two known bugs to keep in mind if this is attempted to be built again from scratch:
# 1. predict() on a svyglm object returns a "svystat" object, not a plain numeric vector
# requires wrapping in as.numeric() before assigning into a column.
# 2. svyglm/svycoxph silently drops rows missing ANY model variable. The predicted-probability
# vector must be assigned back using the exact same complete.cases() logic, not assumed to align
# with a looser NA filter.


library(dplyr)
library(survey)
library(gtsummary)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")

# ---- Binary exposure ----
nhanes_design$variables$depression_binary <- ifelse(
  nhanes_design$variables$phq9_score >= 10, 1,
  ifelse(is.na(nhanes_design$variables$phq9_score), NA, 0)
)

# ---- Propensity model ----
design_ps <- subset(nhanes_design, !is.na(depression_binary))

ps_model <- svyglm(
  depression_binary ~ age + sex + race_ethnicity + education + marital_status +
    income_ratio + bmi + smoking_status + diabetes + cvd,
  design = design_ps,
  family = quasibinomial()
)

ps_vars <- c("depression_binary", "age", "sex", "race_ethnicity", "education",
             "marital_status", "income_ratio", "bmi", "smoking_status", "diabetes", "cvd")
complete_ps <- complete.cases(nhanes_design$variables[ps_vars])
predicted_probs <- as.numeric(predict(ps_model, type = "response"))

nhanes_design$variables$ps_score <- NA
nhanes_design$variables$ps_score[complete_ps] <- predicted_probs

# ---- IPTW weight, trimmed at the 99th percentile ----
nhanes_design$variables$ps_weight <- ifelse(
  nhanes_design$variables$depression_binary == 1,
  1 / nhanes_design$variables$ps_score,
  1 / (1 - nhanes_design$variables$ps_score)
)

trim_threshold <- quantile(nhanes_design$variables$ps_weight, 0.99, na.rm = TRUE)
nhanes_design$variables$ps_weight_trimmed <- pmin(nhanes_design$variables$ps_weight, trim_threshold)

nhanes_design$variables$combined_weight <- nhanes_design$variables$wt_mec_adj *
  nhanes_design$variables$ps_weight_trimmed

# ---- Propensity-weighted Cox model ----
design_ps_weighted <- svydesign(
  ids = ~psu, strata = ~strata, weights = ~combined_weight,
  nest = TRUE, data = nhanes_design$variables, na_weights = "warn"
)
design_ps_final <- subset(design_ps_weighted, !is.na(depression_binary))

cox_model_ps <- svycoxph(Surv(permth_exm, mortstat) ~ depression_binary, design = design_ps_final)

# ---- Direct-adjustment comparison model (same binary exposure) ----
design_direct_binary <- subset(nhanes_design, mortstat %in% c(0, 1) & wt_mec_adj > 0 & !is.na(depression_binary))

cox_model_direct_binary <- svycoxph(
  Surv(permth_exm, mortstat) ~ depression_binary + age + sex + race_ethnicity +
    education + marital_status + income_ratio + bmi + smoking_status +
    diabetes + cvd,
  design = design_direct_binary
)

# ---- Save everything ----
saveRDS(cox_model_ps, "data/derived/cox_model_ps.rds")
saveRDS(cox_model_direct_binary, "data/derived/cox_model_direct_binary.rds")

gt::gtsave(as_gt(tbl_regression(cox_model_ps, exponentiate = TRUE)), "docs/sensitivity_ps_weighted.html")
gt::gtsave(as_gt(tbl_regression(cox_model_direct_binary, exponentiate = TRUE)), "docs/sensitivity_direct_binary.html")

cat("Direct adjustment: HR =", round(exp(coef(cox_model_direct_binary))["depression_binary"], 2), "\n")
cat("Propensity weighted: HR =", round(exp(coef(cox_model_ps))["depression_binary"], 2), "\n")
cat("Sensitivity analysis complete.\n")
