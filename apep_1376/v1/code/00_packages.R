# Load required packages for TFN Leniency IV Analysis
# Argentina Tribunal Fiscal de la Nación (TFN) — Tax Dispute Outcomes

library(tidyverse)      # Data wrangling
library(fixest)         # Fast IV/2SLS (feols, felm)
library(lfe)            # Alternative IV (felm)
library(haven)          # Read/write Stata/SAS
library(jsonlite)       # JSON I/O
library(httr)           # HTTP requests (web scraping)
library(rvest)          # HTML parsing
library(lubridate)      # Date handling
library(data.table)     # Fast operations on large data
library(glue)           # String interpolation
library(sandwich)       # Robust SE (HC/HAC)
library(lmtest)         # Coefficient tests
library(broom)          # Tidy regression output

# Set options
set.seed(20260407)
options(digits = 4, scipen = 999)

message("✓ Packages loaded for apep_1376 (Argentina TFN Leniency IV)")
