# 00_packages.R — Load required packages for Taiwan CGT analysis
# apep_1037: The Round-Trip Tax

required_pkgs <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # panel regressions with FE
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "data.table",  # fast data manipulation
  "lubridate",   # date handling
  "xtable",      # LaTeX tables
  "kableExtra",  # enhanced tables
  "sandwich",    # robust SEs
  "lmtest"       # hypothesis tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
