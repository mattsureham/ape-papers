# 00_packages.R — Load required packages for apep_1247
# ARRA Pell Grant expansion and racial enrollment gaps

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "duckdb",        # Read existing DuckDB files
  "jsonlite",      # Write diagnostics.json
  "knitr",         # Table formatting
  "xtable",        # LaTeX table output
  "httr",          # HTTP requests for IPEDS download
  "sandwich",      # Robust standard errors
  "lmtest"         # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
