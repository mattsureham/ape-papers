## 00_packages.R — Load required libraries
## APEP-0991: EU Landing Obligation

required <- c(
  "tidyverse", "fixest", "did", "eurostat", "jsonlite",
  "data.table", "HonestDiD", "kableExtra", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
