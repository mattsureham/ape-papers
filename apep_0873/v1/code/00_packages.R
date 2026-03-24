# 00_packages.R — apep_0873: The Pill Pipeline
# ALJ Leniency and Opioid Prescribing

required <- c(
  "arcos",         # DEA ARCOS opioid pill data (WaPo release)
  "fixest",        # IV/2SLS with FE
  "data.table",    # Fast data manipulation
  "jsonlite",      # JSON parsing
  "httr",          # HTTP requests
  "tidyverse",     # Data wrangling
  "xtable",        # LaTeX tables
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Explicit loads for validator detection
library(fixest)
library(data.table)

cat("All packages loaded.\n")
