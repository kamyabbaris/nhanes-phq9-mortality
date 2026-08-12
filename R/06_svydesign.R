# Build the survey design object
# MEC exam weight divided by 7 pooled cycles; SDMVSTRA confirmed globally unique across cycles (no cross-cycle collision)

library(dplyr)
library(survey)

analytic_data <- readRDS("data/derived/analytic_dataset.rds")

n_cycles <- 7
analytic_data$wt_mec_adj <- analytic_data$wt_mec / n_cycles

nhanes_design <- svydesign(
  ids = ~psu,
  strata = ~strata,
  weights = ~wt_mec_adj,
  nest = TRUE,
  data = analytic_data
)

print(nhanes_design)

saveRDS(nhanes_design, "data/derived/nhanes_design.rds")

n_clusters <- analytic_data %>% distinct(strata, psu) %>% nrow()
cat("\nDesign object saved. Clusters:", n_clusters, "\n")
