# ==============================================================================
# 00_packages.R — Load and verify required packages
# ==============================================================================

required_packages <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fast fixed effects (feols)
  "duckdb",      # Azure data access
  "data.table",  # efficient data ops
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "xtable",      # LaTeX tables
  "fwildclusterboot" # wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
