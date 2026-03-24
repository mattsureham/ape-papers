# 00_packages.R — Install and load required packages
# apep_0849: Taiwan IIA R&D Tax Credit Transition

required <- c("tidyverse", "fixest", "data.table", "xtable", "jsonlite", "kableExtra")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
