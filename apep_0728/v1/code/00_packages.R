## 00_packages.R — apep_0728
## PNTR × Black-White Manufacturing Earnings Gap (DDD)

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects estimation
  "arrow",        # read parquet from Azure
  "DBI",          # database interface
  "duckdb",       # in-process SQL for parquet
  "data.table",   # memory-efficient operations
  "modelsummary", # publication-quality tables
  "kableExtra",   # LaTeX table formatting
  "jsonlite",     # write diagnostics.json
  "httr"          # download Pierce-Schott data
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
