## 00_packages.R — Load and install required packages
## APEP-0935: First Step Act Safety Valve and Judge Leniency

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed-effects estimation
  "data.table",   # efficient data manipulation
  "haven",        # read SAS/SPSS/Stata files
  "jsonlite",     # JSON output for diagnostics
  "xtable",       # LaTeX table generation
  "sandwich",     # robust standard errors
  "lmtest",       # coefficient testing
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
