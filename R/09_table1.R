# Weighted Table 1 by PHQ-9 severity category

library(dplyr)
library(survey)
library(gtsummary)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")

table1 <- nhanes_design %>%
  tbl_svysummary(
    by = phq9_category,
    include = c(age, sex, race_ethnicity, education, marital_status,
                income_ratio, bmi, smoking_status, diabetes, cvd)
  )

table1_gt <- gtsummary::as_gt(table1)
gt::gtsave(table1_gt, "docs/table1.html")

cat("Table 1 saved to docs/table1.html\n")
