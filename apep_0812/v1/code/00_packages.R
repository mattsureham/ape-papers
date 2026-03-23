## 00_packages.R — Load required libraries
## apep_0812: Pump Prices and Le Pen

required_pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "readxl", "httr", "sf", "conleyreg", "modelsummary",
  "xtable", "kableExtra"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
