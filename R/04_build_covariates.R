
# Recodes covariates into one analytic frame
# Smoking, BMI, Diabetes and CVD from SMQ/BMX/DIQ/MCQ; age/sex/race/education/income/marital from DEMO

library(dplyr)

yn_map <- c("Yes"=1, "No"=0)
diabetes_map <- c("Yes"=1, "No"=0) # Borderline and "Don't know deliberately" -> NA
smoke_freq_map <- c("Every day" = "current", "Some days" = "current", "Not at all" = "former")

build_covariates <- function(cyc) {
  smq <- nhanesA::nhanes(paste0("SMQ_",cyc))
  bmx <- nhanesA::nhanes(paste0("BMX_",cyc))
  diq <- nhanesA::nhanes(paste0("DIQ_",cyc))
  mcq <- nhanesA::nhanes(paste0("MCQ_",cyc))

# BMI
  bmx$BMXBMI_clean <- ifelse(
    bmx$BMDSTATS %in% c("Complete data for age group", "Partial: Height and weight obtained"),
    bmx$BMXBMI,
    NA
  )

# Diabetes
  diq$diabetes <- as.numeric(diabetes_map[as.character(diq$DIQ010)])

# CVD composite
  cvd_cols <- c("MCQ160B", "MCQ160C", "MCQ160D", "MCQ160E", "MCQ160F")
  for(col in cvd_cols) {
    mcq[[paste0(col, "_num")]] <- as.numeric(yn_map[as.character(mcq[[col]])])
  }
  mcq$cvd <- apply(mcq[paste0(cvd_cols, "_num")], 1, function(row) {
    if(any(row==1, na.rm=TRUE)) return (1)
    if(all(is.na(row))) return(NA)
    return(0)
  })

# Smoking
  smq$SMQ020_num <- as.numeric(yn_map[as.character(smq$SMQ020)])
  smq$smoking_status <- ifelse(
    smq$SMQ020_num == 0, "never",
    smoke_freq_map[as.character(smq$SMQ040)]
  )

# Merging the four covariate tables together on SEQN
covars <- diq %>%
  select(SEQN, diabetes) %>%
  left_join(select(mcq, SEQN, cvd), by = "SEQN") %>%
  left_join(select(smq, SEQN, smoking_status), by = "SEQN") %>%
  left_join(select(bmx, SEQN, BMXBMI_clean), by = "SEQN")

covars$cycle <- cyc
covars
}

cycle_years <- c(D = "2005_2006", E = "2007_2008", F = "2009_2010", G = "2011_2012",
                  H = "2013_2014", I = "2015_2016", J = "2017_2018")

covariates_list <- list()
for (cyc in names(cycle_years)) {
  covariates_list[[cyc]] <- build_covariates(cyc)
  cat("Built covariates for cycle", cyc, "\n")
}

covariates_all <- do.call(rbind, covariates_list)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(covariates_all, "data/processed/covariates_all.rds")

cat("\nTotal covariate rows:", nrow(covariates_all), "\n")
