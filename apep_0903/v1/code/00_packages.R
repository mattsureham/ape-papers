# 00_packages.R — Required packages for Swiss Second Home Ban RDD
# apep_0903

required <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr",
  "fixest",       # Fast fixed effects
  "rdrobust",     # RDD estimation (Calonico, Cattaneo, Titiunik)
  "rddensity",    # McCrary manipulation test
  "modelsummary", # Table formatting
  "xtable",       # LaTeX table output
  "jsonlite",     # API and diagnostics JSON
  "httr",         # HTTP requests for Swiss APIs
  "sf"            # Spatial data (for municipality matching)
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
