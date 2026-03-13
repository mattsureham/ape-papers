## 00_packages.R — Load and install required packages
## apep_0650: Creative Destruction at the Border

pkgs <- c(
  "tidyverse",     # data wrangling + ggplot2

"data.table",    # fast data manipulation
  "fixest",        # fast fixed effects estimation
  "DBI",           # database interface
  "duckdb",        # DuckDB for Azure Parquet queries
  "arrow",         # Parquet I/O
  "jsonlite",      # diagnostics.json output
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  # fwildclusterboot not available for this R version; use fixest::boot for cluster bootstrap
  "sandwich",      # robust SEs
  "lmtest"         # coeftest
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
