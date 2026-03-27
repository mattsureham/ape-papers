## 00_packages.R — Load and install required packages
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

  "fixest",       # fast fixed effects estimation
  "data.table",   # efficient data handling
  "httr",         # HTTP requests for data download
  "readxl",       # Excel file reading
  "jsonlite",     # JSON output for diagnostics
  "sandwich",     # robust SEs
  "lmtest",       # coefficient testing
  "fwildclusterboot", # wild cluster bootstrap
  "xtable",       # LaTeX table output
  "kableExtra"    # enhanced tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
