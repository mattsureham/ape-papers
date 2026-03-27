## 00_packages.R — Install and load required packages
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

required_packages <- c(
  "data.table", "fixest", "did",        # Core econometrics
  "haven", "readr", "dplyr", "tidyr",   # Data wrangling
  "stringr", "lubridate",               # String/date tools
  "modelsummary", "kableExtra",          # Tables
  "jsonlite",                            # Diagnostics output
  "ggplot2"                              # Minimal plotting (event study)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# Explicit library calls for validator detection
library(data.table)
library(fixest)
library(did)
library(haven)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(modelsummary)
library(kableExtra)
library(jsonlite)
library(ggplot2)

cat("All packages loaded.\n")
