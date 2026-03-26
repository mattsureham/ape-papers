## 00_packages.R — Load and install required packages
## apep_0987: EPA MATS Staggered Compliance and Infant Health

required <- c(
  "tidyverse", "fixest", "did", "data.table", "readxl",
  "httr", "jsonlite", "geosphere", "HonestDiD", "bacondecomp",
  "modelsummary", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
