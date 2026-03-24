# 00_packages.R — Load required packages
library(tidyverse)
library(tidycensus)
library(fixest)
library(did)
library(data.table)
library(jsonlite)

# Set Census API key from environment
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in environment")
census_api_key(census_key, install = FALSE)

cat("All packages loaded successfully.\n")
