## 00_packages.R — Load and install required packages
## apep_1134: EEG Clawback Threshold Bunching

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "httr",         # API calls to Energy-Charts
  "jsonlite",     # parse JSON responses
  "fixest",       # high-dimensional fixed effects
  "data.table",   # fast data manipulation
  "xtable",       # LaTeX table export
  "lubridate",    # date-time handling
  "zoo"           # rolling operations
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(data.table)
library(dplyr)

cat("All packages loaded.\n")
