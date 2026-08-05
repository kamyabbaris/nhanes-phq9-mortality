# Download NHANES demographic + PHQ-9 questionnaire data via nhanesA
# Cycles: 2005-2006 (D) through 2017-2018 (J) -- see README for rationale

library(nhanesA)

cycles <- c("D", "E", "F", "G", "H", "I", "J")

dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)

for (cycle in cycles) {
  demo <- nhanes(paste0("DEMO_", cycle))
  dpq <- nhanes(paste0("DPQ_", cycle))

  saveRDS(demo, file.path("data/raw", paste0("DEMO_", cycle, ".rds")))
  saveRDS(dpq, file.path("data/raw", paste0("DPQ_", cycle, ".rds")))

  cat("Saved cycle", cycle, "\n")
}
