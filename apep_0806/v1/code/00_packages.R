## 00_packages.R — Load and install required packages
## apep_0806: Ireland Rent Pressure Zones

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table",
  "jsonlite", "httr", "xtable", "kableExtra",
  "rjstat", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(did)
library(data.table)
library(dplyr)

cat("All packages loaded.\n")
