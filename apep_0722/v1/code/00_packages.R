# 00_packages.R — Required packages
# apep_0722: Japan's Split-Rate Consumption Tax

required_packages <- c(
  "tidyverse",
  "data.table",
  "fixest",
  "jsonlite",
  "scales"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
