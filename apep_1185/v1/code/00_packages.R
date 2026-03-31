## 00_packages.R — Load required libraries
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE + cluster-robust SEs
  "did",          # Callaway-Sant'Anna
  "jsonlite",     # JSON I/O (diagnostics, API)
  "httr",         # HTTP requests for CDC API
  "fwildclusterboot", # Wild cluster bootstrap
  "modelsummary", # Table formatting
  "kableExtra"    # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
