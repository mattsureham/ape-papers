# 00_packages.R — Install and load required packages for apep_0822

required <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects
  "did",          # Callaway-Sant'Anna
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics output
  "httr",         # API calls
  "sf",           # spatial data
  "haven",        # read Stata files
  "broom"         # tidy model output
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# ColOpenData for Colombian DANE data
if (!requireNamespace("ColOpenData", quietly = TRUE)) {
  install.packages("ColOpenData", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(ColOpenData)

cat("All packages loaded successfully.\n")
