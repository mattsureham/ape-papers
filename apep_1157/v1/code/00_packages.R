## 00_packages.R — Load and install required packages
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

required <- c(
  "tidyverse", "data.table", "fixest", "did",
  "jsonlite", "httr", "readr", "xtable",
  "HonestDiD", "broom"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
