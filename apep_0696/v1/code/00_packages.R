## 00_packages.R — Load all required packages
## apep_0696: FPM fiscal transfers and deforestation in Brazil

# Core data manipulation
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)       # TWFE, 2SLS
library(rdrobust)     # RDD
library(rddensity)    # McCrary/Cattaneo density test
library(rdmulti)      # Multi-cutoff RDD

# Tables
library(modelsummary)
library(kableExtra)

# Output
library(jsonlite)

cat("All packages loaded successfully.\n")
