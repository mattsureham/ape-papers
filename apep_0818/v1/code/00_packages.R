## 00_packages.R — Load required packages
## apep_0818: Zombie Nonprofits

required <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects estimation
  "data.table",   # fast I/O
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "readr",        # CSV reading
  "modelsummary", # regression tables
  "kableExtra",   # LaTeX table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
