## ==============================================================
## 00_packages.R — apep_1293
## Guns In, Guns Out: Firearm Liberalization and Re-Restriction
## on Homicide in Brazil
## ==============================================================

# Core
library(data.table)
library(fixest)

# Data I/O
library(read.dbc)    # DATASUS .dbc compressed files
library(httr)        # API calls (IBGE SIDRA)
library(jsonlite)    # JSON parsing
library(curl)        # FTP downloads

# Tables
library(modelsummary)
library(kableExtra)

# Utilities
library(stringr)

cat("All packages loaded successfully.\n")
