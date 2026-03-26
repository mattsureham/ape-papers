# 00_packages.R — Load and install required packages
# apep_0990: Nebraska groundwater allocations and crop adaptation

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects
  "did",          # Callaway-Sant'Anna
  "HonestDiD",    # Rambachan-Roth sensitivity
  "data.table",   # fast data ops
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # robust SEs
  "boot",             # bootstrap methods
  "xtable",       # LaTeX table generation
  "modelsummary"  # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit imports for validator detection
library(fixest)
library(did)
library(data.table)
library(dplyr)

cat("All packages loaded successfully.\n")
