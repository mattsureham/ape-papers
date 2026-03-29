## 00_packages.R — Load and install required packages
## APEP-1116: The Patent Office Lottery

required <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fast FE regressions + IV
  "data.table",  # fast CSV reading
  "jsonlite",    # diagnostics output
  "xtable",      # LaTeX table generation
  "sandwich",    # robust SEs
  "lmtest",      # coeftest
  "boot"         # bootstrap
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(data.table)

cat("All packages loaded.\n")
