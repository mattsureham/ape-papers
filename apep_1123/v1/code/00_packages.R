## 00_packages.R — Load required packages
## APEP-1123: The Registration Effect

# Set working directory to paper root (one level up from code/)
if (basename(getwd()) == "code") setwd("..")

required_packages <- c(
  "dplyr", "tidyr", "readr", "purrr", "stringr", "lubridate",
  "fixest",       # feols for DiD with fixed effects
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable",       # LaTeX tables
  "jsonlite",     # diagnostics.json output
  "httr2"         # API calls
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
