# 00_packages.R — Load and install required packages
# apep_1229: GIPP and Insurance Market Competition

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects estimation
  "readxl",       # read Excel files (FCA data)
  "httr",         # HTTP requests for data download
  "jsonlite",     # JSON output for diagnostics
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust standard errors
  "broom"         # tidy model output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
