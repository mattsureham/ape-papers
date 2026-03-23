# 00_packages.R — Required packages for apep_0836
# Japan Heisei Municipal Merger Fiscal Cliff

pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Two-way FE, Sun-Abraham, clustered SEs
  "did",           # Callaway & Sant'Anna (2021)
  "readxl",        # Read MIC Excel files
  "httr",          # HTTP requests for data download
  "rvest",         # HTML parsing for MIC page links
  "stringr",       # String manipulation
  "jsonlite",      # Write diagnostics.json
  "xtable",        # LaTeX table generation
  "kableExtra"     # Enhanced LaTeX tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
