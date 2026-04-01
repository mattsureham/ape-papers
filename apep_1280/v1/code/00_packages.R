# ==============================================================================
# 00_packages.R — Package loading for apep_1280
# Minimum Wages and the Racial Labor Income Gap
# ==============================================================================

# Core data manipulation
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)       # Fast fixed effects (feols, sunab)
library(did)          # Callaway-Sant'Anna staggered DiD

# Data access
library(duckdb)       # Azure parquet via DuckDB

# Tables
library(modelsummary) # Regression tables
library(kableExtra)   # Table formatting

# Utilities
library(jsonlite)     # diagnostics.json output

cat("All packages loaded.\n")
