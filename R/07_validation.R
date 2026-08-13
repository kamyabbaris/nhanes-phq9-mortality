# Validation: reproducing a published NCHS weighted prevalence to validate the full pipeline
# Target: NCHS Data Brief No. 303 (Feb 2018) -> 8.1% PHQ-9>=10 prevalence, adults 20+, pooled NHANES 2013-2016 (cycles H+I)

library(dplyr)
library(survey)

analytic_data <- readRDS("data/derived/analytic_dataset.rds")

validation_data <- analytic_data %>% filter(cycle %in% c("H","I"))
validation_data$wt_mec_2cyc <- validation_data$wt_mec /2

design_2cyc <- svydesign(
  ids= ~psu, strata= ~strata, weights= ~wt_mec_2cyc, nest=TRUE, data=validation_data
)

design_20plus <- subset(design_2cyc, age >=20)

result <- svymean(~I(phq9_score >=10), design_20plus, na.rm=TRUE)
print(result)

pct<- round(coef(result)["I(phq9_score >= 10)TRUE"] * 100, 1)
cat("\nMy estimate:", pct, "%\n")
cat("Published (NCHS Data Brief 303): 8.1 %\n")
cat(if (pct==8.1) "MATCH!\n" else "DOES NOT MATCH! -> check weight divisor,age subset, then missing-data rule\n")

