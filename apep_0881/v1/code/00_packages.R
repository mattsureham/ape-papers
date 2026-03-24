# 00_packages.R — Install and load required packages
# apep_0881: Academy Conversion and Pupil Sorting

required <- c(
  "tidyverse", "fixest", "did", "data.table", "httr2", "jsonlite",
  "readr", "lubridate", "xtable", "modelsummary", "kableExtra",
  "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
