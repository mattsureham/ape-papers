## =============================================================================
## 00_packages.R — Into the Dark: Dark Sky Ordinances and Property Values
## apep_0762
## =============================================================================

# Core
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)
library(did)           # Callaway-Sant'Anna

# Inference — use randomization inference for few-cluster robustness

# Tables
library(modelsummary)

# Utilities
library(jsonlite)
library(httr)

cat("All packages loaded successfully.\n")
