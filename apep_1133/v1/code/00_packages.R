## 00_packages.R — Load required packages
## APEP-1133: The Tenure Shield

required <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "sandwich", "lmtest", "modelsummary", "kableExtra",
  "fwildclusterboot", "splines"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
