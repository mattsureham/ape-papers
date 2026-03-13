## 00_packages.R — Install and load required packages
## APEP paper apep_0617: State EITCs and Industry Reallocation

required_packages <- c(
  "duckdb",        # Azure data access via DuckDB
  "data.table",    # Efficient data manipulation
  "fixest",        # Fixed effects / IV estimation
  "did",           # Callaway-Sant'Anna DiD
  "sandwich",      # Robust standard errors
  "lmtest",        # Hypothesis testing
  "jsonlite",      # JSON output for diagnostics
  "xtable",        # LaTeX table generation
  "knitr"          # Table formatting
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
