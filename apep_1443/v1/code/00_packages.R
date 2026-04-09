## 00_packages.R — Taiwan Housing Tax Bunching
## Required packages for bunching analysis

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "data.table",   # fast CSV reading
  "httr",         # HTTP downloads
  "jsonlite",     # JSON output
  "fixest",       # fixed effects regressions
  "sandwich",     # robust SEs
  "boot",         # bootstrap
  "xtable",       # LaTeX tables
  "lubridate"     # date handling
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
