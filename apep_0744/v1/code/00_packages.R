# 00_packages.R — Install and load required packages for apep_0744
# Wales 20mph Speed Limit and Road Safety

pkgs <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fast fixed effects estimation
  "data.table",   # fast data wrangling
  "jsonlite",     # JSON output for diagnostics
  "xtable",       # LaTeX table generation
  "sandwich",     # robust SEs
  "lmtest",       # coefficient testing
  "boot"          # bootstrap
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
