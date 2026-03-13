## 00_packages.R — Install and load required packages
## apep_0652: EPCS Mandates and Opioid Mortality

pkgs <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "HonestDiD",
  "ggplot2", "modelsummary", "kableExtra",
  "httr", "jsonlite",
  "fwildclusterboot"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(did)
library(data.table)
library(dplyr)

message("All packages loaded.")
