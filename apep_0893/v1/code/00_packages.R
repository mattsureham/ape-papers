## 00_packages.R — APEP apep_0893
## Install/load all required packages

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

  "fixest",       # TWFE and Sun-Abraham
  "httr2",        # API calls
  "jsonlite",     # JSON parsing
  "data.table",   # fast data ops
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
