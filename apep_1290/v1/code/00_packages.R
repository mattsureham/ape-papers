# 00_packages.R — Install and load required packages
# APEP Working Paper apep_1290: Enforcement Credibility Ratchet

required <- c(
  "eurostat",     # Eurostat API access
  "jsonlite",     # JSON parsing for CSO PxStat
  "httr",         # HTTP requests
  "dplyr",        # Data wrangling
  "tidyr",        # Reshaping
  "ggplot2",      # Plotting (not used for V1 — zero figures)
  "Synth",        # Synthetic control method
  "fixest",       # Fixed effects estimation
  "zoo",          # Time series (yearqtr)
  "lubridate",    # Date handling
  "stringr",      # String manipulation
  "purrr",        # Functional programming
  "data.table"    # Memory-efficient operations
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
