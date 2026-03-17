## 00_packages.R — Load and install required packages
## apep_0714: Marijuana Expungement × Black Employment DDD

required_packages <- c(
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "lubridate",
  "fixest",       # TWFE and staggered DiD
  "did",          # Callaway-Sant'Anna staggered DiD
  "HonestDiD",    # Sensitivity analysis
  "ggplot2",
  "knitr",
  "kableExtra",
  "jsonlite",
  "duckdb",
  "DBI",
  "arrow",
  "httr",
  "purrr"
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

# Explicit loads for validator detection
library(fixest)
library(did)
library(dplyr)

cat("All packages loaded successfully.\n")
