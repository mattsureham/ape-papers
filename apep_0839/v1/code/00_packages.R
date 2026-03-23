# 00_packages.R — Load required libraries
# apep_0839: TFP Revision and Food Security

required_packages <- c(
  "fixest",       # Two-way fixed effects, cluster SEs
  "data.table",   # Fast data manipulation
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readxl",       # Excel files
  "rvest",        # Web scraping for USDA tables
  "fwildclusterboot",  # Wild cluster bootstrap
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "xtable",       # LaTeX tables
  "sandwich",     # Robust SEs
  "tidycensus"    # Census/ACS data
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
