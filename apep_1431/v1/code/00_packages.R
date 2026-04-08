## 00_packages.R — Install and load all required packages
## Paper: apep_1431 — France DMTO Composition Illusion

# CRAN packages
packages <- c(
  "tidyverse",
  "fixest",         # High-dimensional fixed effects (feols)
  "data.table",     # Memory-efficient data manipulation
  "arrow",          # Out-of-core parquet/CSV processing
  "duckdb",         # In-process SQL analytics
  "jsonlite",       # JSON read/write (diagnostics.json)
  "xtable",         # LaTeX table generation
  "kableExtra",     # Additional table tools
  "scales",         # Number formatting
  "lubridate",      # Date manipulation
  "broom",          # Tidy model outputs
  "modelsummary",   # Regression tables
  "did"             # Callaway-Sant'Anna (backup)
)

# Install missing packages
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org", quiet = TRUE)
}

# Load all packages
invisible(lapply(packages, library, character.only = TRUE))

cat("All packages loaded successfully.\n")
cat("R version:", R.version$version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("data.table version:", as.character(packageVersion("data.table")), "\n")
