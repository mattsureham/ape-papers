## =============================================================================
## 00_packages.R — Load required packages
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "data.table", "arrow", "jsonlite",
  "did", "modelsummary", "kableExtra", "sandwich", "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
