###############################################################################
# 00_packages.R — Load and install required packages
# Paper: The Invisible Tariff (apep_0628)
###############################################################################

required_pkgs <- c(
  "tidyverse",     # Data manipulation and plotting
  "fixest",        # Fast fixed effects estimation
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "data.table",    # Fast data manipulation
  "modelsummary",  # Regression tables
  "kableExtra",    # Table formatting
  "sandwich",      # Robust standard errors
  "lmtest"         # Hypothesis testing
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
