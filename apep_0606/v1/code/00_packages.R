## 00_packages.R — Load and install required packages
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

required_packages <- c(
  "tidyverse",     # data wrangling + ggplot2
  "fixest",        # fast fixed effects (feols, sunab)
  "did",           # Callaway-Sant'Anna
  "data.table",    # fast data manipulation
  "httr",          # API/download
  "jsonlite",      # JSON I/O
  "HonestDiD",     # Rambachan-Roth sensitivity
  "bacondecomp",   # Goodman-Bacon decomposition
  "modelsummary"   # regression tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
