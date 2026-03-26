## 00_packages.R — Install and load required packages
## apep_0978: From Rice Paddies to Solar Panels

required_packages <- c(
  "tidyverse",
  "fixest",
  "httr",
  "jsonlite",
  "readxl",
  "modelsummary",
  "kableExtra",
  "sandwich",
  # "fwildclusterboot",  # not available for this R version
  "data.table"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
