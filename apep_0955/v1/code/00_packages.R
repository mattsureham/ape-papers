# 00_packages.R — Load required libraries
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

library(duckdb)
library(DBI)
library(data.table)
library(fixest)
library(tidyverse)
library(jsonlite)

# Source Azure data access library
source("../../../../scripts/lib/azure_data.R")

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("duckdb version:", as.character(packageVersion("duckdb")), "\n")
