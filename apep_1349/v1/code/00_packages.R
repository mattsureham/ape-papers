## 00_packages.R — Install and load required packages
## APEP-1349: Dutch BPM Multi-Cutoff Bunching

required <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fixed effects regression
  "jsonlite",    # JSON I/O
  "httr",        # HTTP requests
  "data.table",  # fast data manipulation
  "xtable",      # LaTeX table export
  "knitr"        # table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
