# 00_packages.R — Package dependencies for apep_1212
# Anti-Asian Sentiment and Sectoral Reallocation

required_packages <- c(
  "arrow",        # Read Parquet files
  "duckdb",       # Query Azure via DuckDB
  "data.table",   # Fast data manipulation
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "ggplot2",      # Plots (not used in V1 but needed by some helpers)
  "modelsummary", # Table generation
  "kableExtra",   # LaTeX table formatting
  "jsonlite",     # Write diagnostics.json
  "sandwich",     # Robust standard errors
  "fwildclusterboot" # Wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
