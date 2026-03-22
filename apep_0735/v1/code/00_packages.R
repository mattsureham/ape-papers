# 00_packages.R — Load required packages
# apep_0735: ABF Monument Boundary Spatial RDD

required_packages <- c(
  "tidyverse",
  "data.table",
  "fixest",
  "rdrobust",
  "rddensity",
  "jsonlite",
  "sf",
  "httr",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
