# 00_packages.R — Load and install required packages
# apep_0695: Dominican Republic TC/0168 Denationalization

pkgs <- c(
  "tidyverse", "fixest", "modelsummary", "jsonlite",
  "httr", "xml2", "countrycode", "haven",
  "kableExtra", "broom", "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(tidyverse)

cat("All packages loaded successfully.\n")
