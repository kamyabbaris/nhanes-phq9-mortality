library(readr)
library(dplyr)

cycle_years <- c(
 D = "2005_2006", E = "2007_2008", F = "2009_2010", G="2011_2012", H="2013_2014", I="2015_2016", J="2017_2018"
 )

lmf_list <- list()

for(cycle in names(cycle_years)) {
  year_str <- cycle_years[[cycle]]
  file_path <- file.path("data/raw", paste0("NHANES_", year_str, "_MORT_2019_PUBLIC.dat"))

    lmf <- read_fwf(
file_path,
fwf_cols(
publicid=c(1,14),
eligstat=c(15,15),
mortstat=c(16,16),
ucod_leading=c(17,19),
permth_int=c(43,45),
permth_exm=c(46,48)
),
col_types = "ciiiii",
na=c(".","")
)
lmf$seqn <- as.numeric(trimws(lmf$publicid))
lmf$cycle <- cycle

probs <- problems(lmf)
if (nrow(probs) > 0) {
warning(paste("Issues in cycle related to parsing", cycle, "-", nrow(probs), "rows"))
}

lmf_list[[cycle]] <- lmf
cat("Parsed cycle", cycle, "(", year_str,") -", nrow(lmf), "rows\n")
}

lmf_all <- do.call(rbind, lmf_list)

dir.create("data/processed", showWarnings=FALSE, recursive=TRUE)
saveRDS(lmf_all, "data/processed/lmf_combined.rds")

cat("\nTotal rows:", nrow(lmf_all), "\n")
print(table(lmf_all$mortstat, useNA="ifany"))

# Join LMF to DEMO on SEQN, per cycle #

keep_cols <- c(
  "SEQN", "RIAGENDR", "RIDAGEYR", "RIDRETH1","DMDEDUC2", "DMDMARTL", "INDFMPIR",
  "WTINT2YR", "WTMEC2YR", "SDMVPSU", "SDMVSTRA",
  "eligstat", "mortstat", "ucod_leading", "permth_int", "permth_exm", "cycle")
#some column names had changed in later iterations, without the keep_cols it will give an error)


joined_list <- list()

for (cyc in names(cycle_years)) {
  demo <- readRDS(file.path("data/raw", paste0("DEMO_",cyc,".rds")))
  lmf_cyc <- filter(lmf_all, cycle == cyc)

  joined <- left_join(demo, lmf_cyc, by = c("SEQN"="seqn"))

  unmatched <- sum(is.na(joined$eligstat))
  if (unmatched>0) {
    warning(paste("Cycle",cyc,"-",unmatched, "DEMO rows did not match LMF"))
  }

  joined_list[[cyc]] <- select(joined, all_of(keep_cols))
  cat("Joined cycle",cyc,"-",nrow(joined),"rows,",unmatched,"unmatched\n")
}

full_data <- do.call(rbind, joined_list)
cat("\nTotal joined rows:", nrow(full_data), "\n")

# Applying mortality-linkage eligibility #

eligible_data <- filter(full_data, eligstat==1)

cat("Eligible (eligstat==1):", nrow(eligible_data), "\n")
cat("Excluded (under 18 / insufficient data):", nrow(full_data) - nrow(eligible_data), "\n")

saveRDS(eligible_data, "data/processed/nhanes_mortality_linked.rds")

