# ==============================================================================
# 00_packages.R — Package installation and loading
# APEP Paper: Does Cleaning the List Clean the Water?
# ==============================================================================

# Install if needed
pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "dataRetrieval", "httr", "rvest", "xml2",
  "sandwich", "lmtest", "HonestDiD", "bacondecomp",
  "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

# rATTAINS may need special handling
if (!requireNamespace("rATTAINS", quietly = TRUE)) {
  install.packages("rATTAINS", repos = "https://cloud.r-project.org", quiet = TRUE)
}

# Load
library(tidyverse)
library(fixest)
library(did)
library(data.table)
library(jsonlite)
library(dataRetrieval)
library(sandwich)
library(lmtest)

cat("All packages loaded successfully.\n")
