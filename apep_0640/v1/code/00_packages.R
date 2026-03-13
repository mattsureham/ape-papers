## 00_packages.R — Load required packages
## apep_0640: E-Verify Mandates and Hispanic Employment

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

  "fixest",       # fast fixed effects (feols, sunab)
  "did",          # Callaway-Sant'Anna
  "data.table",   # fast data ops
  "arrow",        # read parquet from Azure
  "DBI",          # database interface
  "duckdb",       # in-process analytics
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics JSON
  "sandwich",     # robust SEs
  "fwildclusterboot" # wild cluster bootstrap
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
