## 00_packages.R — Install and load required packages
## APEP paper apep_0614: CEJST Justice40 RDD

required_packages <- c(
  "data.table",    # Memory-efficient data manipulation
  "httr2",         # API calls
  "jsonlite",      # JSON parsing
  "rdrobust",      # RDD estimation
  "rddensity",     # McCrary density test
  "fixest",        # Fast fixed effects (for robustness)
  "modelsummary",  # Table formatting
  "kableExtra",    # LaTeX table output
  "ggplot2",       # (for diagnostics only, no figures in V1)
  "sf"             # Spatial operations (geocoding to tracts)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat(paste("R version:", R.version.string, "\n"))
cat(paste("rdrobust version:", packageVersion("rdrobust"), "\n"))
cat(paste("rddensity version:", packageVersion("rddensity"), "\n"))
