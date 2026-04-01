# 00_packages.R — Required packages for apep_1270
# Swiss CO2 Levy and Heating Capital Stock Decarbonization

required_packages <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "readr", "stringr",
  "fixest", "modelsummary", "kableExtra",
  "sandwich", "lmtest", "fwildclusterboot",
  "ggplot2"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
