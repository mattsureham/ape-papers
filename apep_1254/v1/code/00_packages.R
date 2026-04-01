## 00_packages.R — Load and install required packages
## apep_1254: Portugal Golden Visa Geographic Restriction

required_packages <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "readr", "lubridate",
  "fixest", "modelsummary", "broom", "sandwich", "lmtest",
  "HonestDiD", "ggplot2", "kableExtra",
  "stringr", "purrr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
