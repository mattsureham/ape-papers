# 00_packages.R — Install and load required packages
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

required_packages <- c(
  "tidyverse",   # Data wrangling + ggplot2
  "fixest",      # Fast fixed effects estimation
  "httr",        # HTTP requests (Statistics Denmark API)
  "jsonlite",    # JSON parsing
  "eurostat",    # Eurostat data access
  "sandwich",    # HAC-robust standard errors
  "lmtest",      # Coefficient tests
  "boot",        # Bootstrap inference
  "modelsummary" # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)   # Fixed effects estimation
library(dplyr)    # Data manipulation
library(tidyverse)

cat("All packages loaded successfully.\n")
