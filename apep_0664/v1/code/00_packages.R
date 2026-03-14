## 00_packages.R — Install and load required packages
## apep_0664: Finland Competitiveness Pact

required_packages <- c(
  "tidyverse", "fixest", "modelsummary", "jsonlite",
  "httr", "readr", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
