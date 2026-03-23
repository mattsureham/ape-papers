## 00_packages.R — Load and install required packages
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # high-dimensional fixed effects
  "data.table",   # fast data manipulation
  "arrow",        # read parquet from Azure
  "httr",         # Census API calls
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coefficient testing
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
