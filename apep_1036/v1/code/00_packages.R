## 00_packages.R — Install and load required packages
## apep_1036: Tax Office Closures and Far-Right Voting in France

required <- c(
  "arrow",       # Parquet I/O
  "data.table",  # Fast data manipulation
  "fixest",      # Panel regressions (feols, CS-DiD)
  "did",         # Callaway-Sant'Anna estimator
  "ggplot2",     # Not used in V1 (no figures), but needed for did::aggte plot internals
  "jsonlite",    # diagnostics.json
  "readr",       # CSV reading
  "stringr",     # String manipulation
  "kableExtra",  # Table formatting
  "xtable"       # LaTeX tables
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
