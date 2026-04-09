# 00_packages.R — Install and load required packages
# PFAS/Karst Spatial RDD — apep_1440

required <- c(
  "tidyverse", "fixest", "rdrobust", "rddensity",
  "sf", "jsonlite", "httr", "readr", "xtable",
  "data.table", "modelsummary", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
