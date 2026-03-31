# 00_packages.R — Load required libraries
# apep_1202: Broadband preemption and telehealth adoption

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# Data fetching
library(httr)
library(jsonlite)
library(tidycensus)

# Econometrics
library(fixest)       # TWFE, Sun-Abraham
library(did)          # Callaway-Sant'Anna
library(sandwich)     # Robust SEs
library(lmtest)       # Coefficient tests

# Tables
library(modelsummary)
library(kableExtra)

cat("All packages loaded successfully.\n")
