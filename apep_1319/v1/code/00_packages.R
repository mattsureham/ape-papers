# 00_packages.R — Package installation and loading for apep_1319
# UK Anti-Social Behaviour toolkit consolidation (2014 Act)

required_packages <- c(
  "data.table", "fixest", "ggplot2", "httr", "jsonlite",
  "readr", "stringr", "lubridate", "sandwich", "lmtest",
  "modelsummary", "kableExtra", "purrr", "boot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
