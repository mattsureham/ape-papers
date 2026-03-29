## 00_packages.R — Install and load required packages
## APEP-1112: The Alliance Ratchet

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "jsonlite", "httr", "broom", "kableExtra",
  "xtable", "sandwich", "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
