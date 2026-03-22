# 00_packages.R — Load required libraries
# APEP-0750: The Innovation Offshore Effect

required <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fast fixed effects estimation
  "data.table",  # fast data manipulation
  "jsonlite",    # write diagnostics.json
  "xtable",      # LaTeX table generation
  "sandwich",    # robust SEs
  "lmtest",      # coefficient tests
  "modelsummary" # publication-quality tables
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
