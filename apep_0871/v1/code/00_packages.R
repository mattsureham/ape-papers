# 00_packages.R — Load required libraries
# apep_0871: NIS2 Cybersecurity Regulation and Enterprise Security Investment

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(fixest)
  library(eurostat)
  library(httr2)
  library(jsonlite)
  library(xtable)
})

message("All packages loaded.")
