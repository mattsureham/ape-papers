## 00_packages.R — Load and install required packages
## APEP-0807: Legislating at Midnight

required_packages <- c(
  "httr", "jsonlite",     # API access
  "dplyr", "tidyr", "purrr", "stringr", "lubridate", # data wrangling
  "fixest",               # fixed effects regression
  "modelsummary",         # regression tables
  "xtable",               # LaTeX tables
  "sandwich", "lmtest"    # robust SEs
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
