## 00_packages.R — Load required libraries
## apep_1177: The Classification Lottery

# Core
library(data.table)
library(arrow)
library(jsonlite)

# IV / Econometrics
library(fixest)      # feols, feiv — fast FE-IV with clustering
library(ivreg)       # ivreg — classical 2SLS + diagnostics

# Diagnostics
library(sandwich)    # vcovCL — cluster-robust SEs
library(lmtest)      # coeftest — hypothesis tests

# Tables
library(modelsummary) # msummary — regression tables
library(kableExtra)   # kbl — LaTeX tables

# Utilities
library(ggplot2)     # descriptive plots (for diagnostics only, no figures in V1)
library(stringr)
library(lubridate)

cat("All packages loaded for apep_1177.\n")
