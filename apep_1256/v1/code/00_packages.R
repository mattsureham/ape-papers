## ============================================================================
## 00_packages.R — apep_1256
## Donor-funded mayors and procurement capture in Colombia
## ============================================================================

# Core
library(tidyverse)
library(data.table)
library(jsonlite)

# Econometrics
library(fixest)       # High-dimensional FE
library(rdrobust)     # RDD estimation
library(rddensity)    # McCrary density test
library(sandwich)     # Robust SEs
library(lmtest)       # Coeftest

# Tables
library(modelsummary) # Regression tables
library(kableExtra)   # Table formatting

# Data fetching
library(httr)         # HTTP requests for Socrata API
library(curl)         # For downloading

cat("All packages loaded.\n")
