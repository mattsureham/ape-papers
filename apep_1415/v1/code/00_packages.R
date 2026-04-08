# 00_packages.R — Install and load required packages
# APEP 1415: Morocco Cannabis Legalization

required_packages <- c(
  "tidyverse", "fixest", "did", "sf", "terra", "exactextractr",
  "httr", "jsonlite", "rstudioapi", "data.table", "sandwich",
  "lmtest", "stargazer", "xtable", "broom",
  "rdrobust", "rddensity", "modelsummary", "clubSandwich"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
