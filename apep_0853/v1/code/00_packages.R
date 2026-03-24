## 00_packages.R — Load and install required packages
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

required_packages <- c(
  "tidyverse", "data.table", "fixest", "did", "modelsummary",
  "httr", "jsonlite", "kableExtra", "xtable", "HonestDiD",
  "bacondecomp", "sandwich", "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
