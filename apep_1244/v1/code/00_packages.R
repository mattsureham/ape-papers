# =============================================================================
# 00_packages.R — Load required packages
# apep_1244: The Upgrading Dividend
# =============================================================================

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)

# Econometrics
library(fixest)        # TWFE, Sun-Abraham
library(did)           # Callaway-Sant'Anna
library(sandwich)      # Robust SEs
library(lmtest)        # Coefficient tests

# Tables and output
library(modelsummary)
library(kableExtra)
library(jsonlite)

# Azure data access
source("../../../../scripts/lib/azure_data.R")

cat("All packages loaded successfully.\n")
