## 00_packages.R — Load required packages for FOBT analysis

required_packages <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fast fixed effects estimation
  "httr",         # HTTP requests for data download
  "readxl",       # read Excel files
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX table generation
  "sandwich",     # robust SEs
  "lmtest",       # coefficient testing
  "boot"             # bootstrap methods
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
