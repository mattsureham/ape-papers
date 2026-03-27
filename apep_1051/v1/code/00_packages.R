# 00_packages.R — Load and install required packages
# apep_1051: CRP Cap Reduction and Land-Use Transitions

required_pkgs <- c(
  "tidyverse",     # Data wrangling + ggplot2
  "fixest",        # Fast fixed effects estimation
  "did",           # Callaway-Sant'Anna DiD
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "data.table",    # Fast data manipulation
  "xtable",        # LaTeX table generation
  "modelsummary",  # Regression tables
  "kableExtra"     # Table formatting
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
