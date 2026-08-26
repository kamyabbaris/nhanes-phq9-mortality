# Table 1 by PHQ-9 severity category
# Restricted to complete cases entering the Cox model (n = 26,333)
# Counts are unweighted (actual participants); medians remain survey-weighted

library(dplyr)
library(survey)
library(gtsummary)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")

model_vars <- c("phq9_category", "age", "sex", "race_ethnicity", "education",
                "marital_status", "income_ratio", "bmi", "smoking_status",
                "diabetes", "cvd", "permth_exm", "mortstat")

nhanes_design$variables$.complete <- complete.cases(nhanes_design$variables[model_vars])

design_table1 <- subset(nhanes_design,
                        mortstat %in% c(0, 1) & wt_mec_adj > 0 & .complete)

table1 <- design_table1 %>%
  tbl_svysummary(
    by = phq9_category,
    include = c(age, sex, race_ethnicity, education, marital_status,
                income_ratio, bmi, smoking_status, diabetes, cvd),
    statistic = list(
      all_categorical() ~ "{n_unweighted} ({p_unweighted}%)",
      all_continuous() ~ "{median} ({p25}, {p75})"
    ),
    missing_stat = "{N_miss_unweighted}"
  ) %>%
  modify_header(all_stat_cols() ~ "**{level}**  \nN = {n_unweighted}")

table1_gt <- gtsummary::as_gt(table1)
gt::gtsave(table1_gt, "docs/table1.html")

cat("Table 1 saved to docs/table1.html\n")
