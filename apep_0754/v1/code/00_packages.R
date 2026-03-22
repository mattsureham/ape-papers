## 00_packages.R — Load and install required packages
## APEP Working Paper apep_0754

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE, Sun-Abraham, high-dimensional FE
  "did",          # Callaway-Sant'Anna
  "data.table",   # fast data manipulation
  "readxl",       # read Excel files
  "jsonlite",     # JSON output for diagnostics
  "httr",         # HTTP requests for data download
  "HonestDiD",    # Rambachan-Roth sensitivity
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coefficient testing
)

for (pkg in pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
