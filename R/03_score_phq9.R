
# Score PHQ-9 and cut into severity categories
# Complete-case scoring: all 9 items required, any single missing items -> NA score
# DPQ100 (difficulty) excluded since it is not a part of the PHQ-9 score itself


response_map <- c(
  "Not at all" = 0,
  "Several days" = 1,
  "More than half the days" = 2,
  "Nearly every day" = 3
)

dpq_items <- paste0("DPQ0", sprintf("%02d", 1:9 *10))

score_phq9 <- function (dpq_data, cycle_label) {
  for (item in dpq_items) {
    dpq_data[[paste0(item, "_num")]] <- as.numeric(response_map[as.character(dpq_data[[item]])])
  }

  dpq_data$phq9_score <- rowSums(dpq_data[paste0(dpq_items, "_num")])
  dpq_data$phq9_category <- cut(
    dpq_data$phq9_score,
    breaks = c(-1,4,9,14,19,27),
    labels = c("Minimal (0-4)", "Mild (5-9)", "Moderate (10-14)", "Moderately severe (15-19)", "Severe (20-27)")
  )

  dpq_data$cycle <- cycle_label
  select(dpq_data, SEQN, cycle, phq9_score, phq9_category)
}

library(dplyr)

cycle_years <- c(D = "2005_2006", E = "2007_2008", F = "2009_2010", G = "2011_2012",
                  H = "2013_2014", I = "2015_2016", J = "2017_2018")

phq9_list <- list()
for (cyc in names(cycle_years)) {
  dpq <- readRDS(file.path("data/raw", paste0("DPQ_", cyc, ".rds")))
  phq9_list[[cyc]] <- score_phq9(dpq, cyc)
  cat("Scored cycle", cyc, "\n")
}

phq9_all <- do.call(rbind, phq9_list)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(phq9_all, "data/processed/phq9_scored.rds")

cat("\nPooled frequency table:\n")
print(table(phq9_all$phq9_category, useNA = "ifany"))
