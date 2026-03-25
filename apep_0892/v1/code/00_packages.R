# 00_packages.R — Required packages for apep_0892
# Moldova Wine Embargo and Subnational Economic Activity

required_packages <- c(
  "data.table",
  "fixest",
  "ggplot2",
  "httr2",
  "jsonlite",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "purrr",
  "sandwich",
  "lmtest",
  "clubSandwich",    # Wild cluster bootstrap
  "boot",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
