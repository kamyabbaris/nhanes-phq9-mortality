# Proportional hazards assumption check and age-stratified refit
# cox.zph() is documented for coxph() fits, not svycoxph -- running it directly
# on a svycoxph object produced degenerate results (near-zero chisq, p ~ 1
# everywhere). A parallel coxph model, using case weights (normalized to the
# real sample size, not survey-design weights), is used for this diagnostic
# only. The reported hazard ratios throughout this project come from the
# properly survey-weighted svycoxph model.

library(survival)
library(survey)
library(gtsummary)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")
design_cox <- subset(nhanes_design, mortstat %in% c(0, 1) & wt_mec_adj > 0)

# ---- PH diagnostic (weighted coxph, for cox.zph only) ----
model_vars <- c("phq9_category", "age", "sex", "race_ethnicity", "education",
                 "marital_status", "income_ratio", "bmi", "smoking_status",
                 "diabetes", "cvd", "permth_exm", "mortstat")

model_data <- design_cox$variables[complete.cases(design_cox$variables[model_vars]), ]
model_data$wt_normalized <- model_data$wt_mec_adj / mean(model_data$wt_mec_adj)

coxph_check <- coxph(
  Surv(permth_exm, mortstat) ~ phq9_category + age + sex + race_ethnicity +
    education + marital_status + income_ratio + bmi + smoking_status +
    diabetes + cvd,
  data = model_data,
  weights = wt_normalized
)

zph_check <- cox.zph(coxph_check)
print(zph_check)

# ---- Remedy: stratify age (largest violation); document sex/CVD as limitations ----
nhanes_design$variables$age_group <- cut(
  nhanes_design$variables$age,
  breaks = c(-1, 39, 59, 74, Inf),
  labels = c("18-39", "40-59", "60-74", "75+")
)

design_cox <- subset(nhanes_design, mortstat %in% c(0, 1) & wt_mec_adj > 0)

cox_model_v2 <- svycoxph(
  Surv(permth_exm, mortstat) ~ phq9_category + strata(age_group) + sex +
    race_ethnicity + education + marital_status + income_ratio + bmi +
    smoking_status + diabetes + cvd,
  design = design_cox
)

saveRDS(cox_model_v2, "data/derived/cox_model_ph_adjusted.rds")

hr_table_v2 <- tbl_regression(cox_model_v2, exponentiate = TRUE)
hr_table_v2_gt <- as_gt(hr_table_v2)
gt::gtsave(hr_table_v2_gt, "docs/cox_model_v2_hr_table.html")

cat("PH-adjusted model n =", cox_model_v2$n, ", events =", cox_model_v2$nevent, "\n")
cat("Saved cox_model_ph_adjusted.rds and cox_model_v2_hr_table.html\n")
