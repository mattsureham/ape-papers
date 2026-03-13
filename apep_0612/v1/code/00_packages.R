## 00_packages.R — Load and install required packages
## apep_0612: Immigration Judge Leniency and Local Crime

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2

  "fixest",       # IV regression (feols), robust SEs
  "jsonlite",     # API JSON parsing
  "httr",         # HTTP requests
  "tidycensus",   # ACS demographics
  "modelsummary", # regression tables in LaTeX
  "kableExtra",   # table formatting
  "sandwich",     # robust covariance estimators
  "lmtest"        # coefficient tests
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
