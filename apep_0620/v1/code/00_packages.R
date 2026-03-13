# 00_packages.R — Install and load required packages
# apep_0620: Second-generation refugee dispersal outcomes in Denmark

required_packages <- c(
  "httr", "jsonlite",  # StatBank API
  "dplyr", "tidyr", "stringr", "purrr", "readr",  # Data wrangling
  "fixest",            # Fixed effects regression
  "sandwich", "lmtest", # Robust inference
  "xtable",            # LaTeX tables
  "boot"               # Bootstrap inference
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
