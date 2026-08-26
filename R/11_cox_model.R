# Adjusted Cox proportional hazards model: PHQ-9 severity and all-cause mortality
# Exposure: phq9_category (Minimal = reference)
# Adjustment: age, sex, race/ethnicity, education, marital status, income ratio, BMI, smoking, diabetes, CVD
# svycoxph requires explicit exclusion of zero-weight rows (a known package quirk, not a data issue)

library(survey)
library(broom.helpers) #note for future people looking to get into this stuff, git commit step by step what you do, I almost just nuked the entire renv.lock on this step accidentally! praise the git log. 
library(gtsummary)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")

# Complete-case analysis: pre-specified policy. Missingness in PHQ-9 items and
# MEC attendance is plausibly MNAR (severity drives non-response), so multiple
# imputation would not remove the bias. Applied explicitly here rather than
# relying on the default na.action inside svycoxph().

model_vars <- c("phq9_category", "age", "sex", "race_ethnicity", "education",
                "marital_status", "income_ratio", "bmi", "smoking_status",
                "diabetes", "cvd", "permth_exm", "mortstat")

nhanes_design$variables$.complete <- complete.cases(nhanes_design$variables[model_vars])

design_cox <- subset(nhanes_design,
                     mortstat %in% c(0, 1) & wt_mec_adj > 0 & .complete)

cox_model <- svycoxph(
  Surv(permth_exm, mortstat) ~ phq9_category + age + sex + race_ethnicity +
    education + marital_status + income_ratio + bmi + smoking_status +
    diabetes + cvd,
  design = design_cox
)

saveRDS(cox_model, "data/derived/cox_model.rds")

hr_table <- tbl_regression(cox_model, exponentiate = TRUE)
hr_table_gt <- as_gt(hr_table)
gt::gtsave(hr_table_gt, "docs/cox_model_hr_table.html")

cat("Model n =", cox_model$n, ", events =", cox_model$nevent, "\n")
cat("Cox model and HR table saved.\n")
