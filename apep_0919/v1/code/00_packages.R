# ===========================================================================
# 00_packages.R — Package loading for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(eurostat)
  library(eurlex)
  library(httr2)
  library(jsonlite)
  library(fixest)
  library(did)
  library(xtable)
  library(sandwich)
  library(lmtest)
  library(fwildclusterboot)
})

cat("All packages loaded.\n")
