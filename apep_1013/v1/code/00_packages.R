# 00_packages.R — Load required packages for apep_1013
# Egypt energy subsidy reform and manufacturing

required_packages <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "purrr", "readr", "stringr",
  "fixest", "modelsummary", "kableExtra",
  "fwildclusterboot", "sandwich", "lmtest",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
