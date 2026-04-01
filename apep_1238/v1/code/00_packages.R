## 00_packages.R — apep_1238
## Hill-Burton Hospital Infrastructure, Market Concentration, and Medicare Spending

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast IV/2SLS with robust SEs
  "data.table",   # fast data processing
  "jsonlite",     # JSON I/O
  "httr",         # HTTP requests
  "rvest",        # web scraping
  "readxl",       # Excel reading
  "haven",        # Stata/SAS files
  "knitr",        # tables
  "kableExtra",   # LaTeX tables
  "xtable",       # LaTeX table output
  "sandwich",     # heteroskedasticity-robust SEs
  "lmtest"        # hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
