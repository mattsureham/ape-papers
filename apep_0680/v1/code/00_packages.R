## 00_packages.R — Load libraries and set global options
## apep_0680: ZFE Spatial RDD on Property Values

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(rdrobust)
  library(rddensity)
  library(fixest)
  library(jsonlite)
  library(data.table)
})

options(
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

cat("All packages loaded successfully.\n")
