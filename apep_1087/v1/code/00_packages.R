## 00_packages.R — Load required libraries
## apep_1087: Healthcare WVP Mandates and Worker Injuries

required_packages <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "httr", "modelsummary", "kableExtra", "sandwich"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
