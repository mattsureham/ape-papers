# 00_packages.R — Load and install required packages
# apep_1021: Latvia AML Shell-Company Ban

required <- c(
  "tidyverse", "data.table", "fixest", "lubridate",
  "modelsummary", "kableExtra", "jsonlite", "httr"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
