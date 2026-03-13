# 00_packages.R — Install and load required packages
# apep_0644: Pay Transparency Mandates and Employer Adjustment

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Fast data operations
  "arrow",        # Parquet file reading
  "DBI",          # Database interface
  "duckdb",       # In-memory analytics
  "modelsummary", # Table generation
  "kableExtra",   # Table formatting
  "jsonlite",     # JSON output for diagnostics
  "HonestDiD",    # Sensitivity analysis
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
