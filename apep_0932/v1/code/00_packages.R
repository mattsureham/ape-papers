# 00_packages.R — apep_0932: New Deal WPA and Racial Occupational Mobility
# Required packages for analysis

required <- c(
  "duckdb",        # Azure parquet access
  "data.table",    # Fast data manipulation (128GB RAM allows in-memory)
  "fixest",        # feols for FE regressions
  "did",           # Callaway-Sant'Anna (if needed)
  "modelsummary",  # Regression tables
  "xtable",        # LaTeX table output
  "jsonlite",      # diagnostics.json
  "kableExtra"     # Table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
