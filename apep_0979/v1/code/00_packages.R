# =============================================================================
# 00_packages.R — Load required packages for apep_0979
# =============================================================================

library(tidyverse)
library(fixest)
library(duckdb)
library(arrow)
library(jsonlite)
# fwildclusterboot not available for this R version; use CR3 correction instead
library(did)
library(modelsummary)
