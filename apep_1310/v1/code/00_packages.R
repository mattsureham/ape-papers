# 00_packages.R — Load required packages
# APEP-1310: The Compression Shock

required <- c(
  "tidyverse",   # data manipulation
  "fixest",      # fast fixed effects
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "sandwich",    # robust SEs
  "lmtest",      # coeftest
  "boot",        # bootstrap
  "modelsummary" # regression tables
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
