## 00_packages.R — The Fifty-Bed Cliff
## Install and load required packages

required_packages <- c(
  "tidyverse",
  "data.table",
  "fixest",
  "xtable",
  "jsonlite",
  "httr",
  "readr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
