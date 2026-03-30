## 00_packages.R — apep_1136: FCA Persistent Debt Rule
## Install and load required packages

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "data.table",   # fast data operations
  "readxl",       # Excel files
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "sandwich",     # HAC standard errors
  "lmtest",       # coeftest with HAC
  "zoo",          # time series operations
  "tseries",      # time series tests
  "xtable",       # LaTeX table output
  "lubridate",    # date handling
  "fixest"        # high-performance estimation
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
