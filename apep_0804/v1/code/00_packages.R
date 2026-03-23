# 00_packages.R — Load and install required packages
# APEP Paper apep_0804: The Caregiving Tax

required_packages <- c(
  "tidycensus",    # ACS PUMS microdata
  "data.table",    # Fast data manipulation
  "fixest",        # High-dimensional FE regression
  "did",           # Callaway-Sant'Anna estimator
  "dplyr",         # Data wrangling
  "tidyr",         # Reshaping
  "stringr",       # String operations
  "jsonlite",      # Write diagnostics.json
  "xtable",        # LaTeX table output
  "knitr"          # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Load Census API key from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
census_line <- grep("^CENSUS_API_KEY=", env_lines, value = TRUE)
if (length(census_line) == 0) stop("CENSUS_API_KEY not found in .env")
census_key <- sub("^CENSUS_API_KEY=", "", census_line[1])
census_api_key(census_key, install = FALSE)

cat("All packages loaded. Census API key set.\n")
