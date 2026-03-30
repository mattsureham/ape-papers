## ============================================================
## 00_packages.R — Load required R packages
## apep_1124: Sanctions at Sea
## ============================================================

# Core
library(tidyverse)
library(data.table)
library(fixest)

# Causal inference
library(did)  # Callaway-Sant'Anna

# Tables
library(kableExtra)
library(xtable)

# Utilities
library(jsonlite)
library(httr)

cat("All packages loaded.\n")
