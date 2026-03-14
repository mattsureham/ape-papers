# 00_packages.R — Install and load required packages
# apep_0667: EBT rollout and drug-market activity

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast FE estimation
  "did",          # Callaway-Sant'Anna DiD
  "fredr",        # FRED API access
  "httr2",        # HTTP requests (FBI API)
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "HonestDiD"     # sensitivity analysis for pre-trends
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
