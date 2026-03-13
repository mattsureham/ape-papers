# =============================================================================
# 00_packages.R — Load libraries for apep_0663
# Breaking Job Lock: Medicaid Expansion and Worker Mobility
# =============================================================================

library(tidyverse)
library(fixest)
library(did)
library(data.table)
library(duckdb)
library(DBI)
library(jsonlite)

# Azure data access
source("../../../../scripts/lib/azure_data.R")

cat("Packages loaded successfully.\n")
