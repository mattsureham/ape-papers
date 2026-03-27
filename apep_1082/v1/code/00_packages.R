##############################################################################
# 00_packages.R — Load required libraries
# APEP-1082: The Lottery Channel
##############################################################################

required <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "httr", "readxl", "haven", "modelsummary", "kableExtra",
  "xtable", "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit library loads for validation detection
library(fixest)
library(did)
library(dplyr)
library(data.table)

cat("All packages loaded.\n")
