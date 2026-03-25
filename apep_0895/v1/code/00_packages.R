# 00_packages.R — Install and load required packages for apep_0895
# AML Regulation and Money Laundering Detection

pkgs <- c(
  "data.table", "dplyr", "tidyr", "ggplot2",
  "fixest", "did",         # DiD estimators
  "eurostat",              # Eurostat data
  "eurlex",                # CELLAR SPARQL for transposition dates
  "httr2", "jsonlite",    # API queries
  "sandwich", "lmtest",   # Robust inference
  "fwildclusterboot",     # Wild cluster bootstrap
  "modelsummary",         # Table formatting
  "kableExtra",           # LaTeX table styling
  "HonestDiD"             # Sensitivity analysis
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(fixest)
  library(did)
  library(eurostat)
  library(httr2)
  library(jsonlite)
  library(sandwich)
  library(lmtest)
  library(modelsummary)
  library(kableExtra)
})

message("All packages loaded successfully.")
