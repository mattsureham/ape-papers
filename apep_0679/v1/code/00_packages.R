## 00_packages.R — Install and load required packages
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out

required_packages <- c(
  "tidyverse", "fixest", "data.table", "httr2", "readxl",
  "jsonlite", "haven", "broom", "modelsummary", "kableExtra",
  "xtable", "sandwich", "here"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
