# ==============================================================================
# 00_packages.R — The Waterbed Effect (apep_1149)
# ==============================================================================

required <- c(
  "duckdb",        # Azure Parquet access
  "arrow",         # Parquet I/O
  "data.table",    # Fast data manipulation
  "fixest",        # Two-way FE estimation, event studies
  "modelsummary",  # Table generation
  "xtable",        # LaTeX table output
  "jsonlite",      # diagnostics.json
  "httr",          # API calls
  "stringr"        # String operations
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
