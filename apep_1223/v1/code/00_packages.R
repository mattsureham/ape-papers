## 00_packages.R — apep_1223: The Choice Tax
## Required packages for UK Pension Freedoms analysis

pkgs <- c(
  "readxl",      # Excel parsing
  "data.table",  # Fast data manipulation
  "fixest",      # Fixed effects regressions
  "modelsummary", # Regression tables
  "kableExtra",  # Table formatting
  "jsonlite",    # Diagnostics output
  "xtable"       # LaTeX table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
