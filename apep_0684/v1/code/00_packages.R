## 00_packages.R — Install/load required packages
## MATS Compliance Bifurcation (apep_0684)

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects / IV
  "data.table",   # fast data I/O
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
