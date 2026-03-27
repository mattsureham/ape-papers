# =============================================================================
# 00_packages.R — APEP 1074: The Detection Dividend
# =============================================================================
required_packages <- c(
  "tidyverse", "fixest", "httr", "jsonlite",
  "modelsummary", "kableExtra", "data.table"
)
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}
message("All packages loaded.")
