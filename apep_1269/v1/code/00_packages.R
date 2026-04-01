## 00_packages.R — Load required libraries
## APEP Paper: Mexico's Sorteo Militar and Youth Crime

required_pkgs <- c(
  "tidyverse",   # data manipulation + ggplot2
  "fixest",      # fast fixed effects (feols)
  "data.table",  # fast data I/O
  "httr",        # HTTP requests for data download
  "readxl",      # read Excel files
  "jsonlite",    # JSON I/O
  "sandwich",    # robust SEs
  "lmtest",      # coeftest
  "kableExtra"   # LaTeX table formatting
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
