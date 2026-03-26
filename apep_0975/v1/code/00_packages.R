## 00_packages.R — Install and load required packages
## apep_0975: European Investigation Order and Crime Deterrence

required <- c(
  "data.table", "dplyr", "fixest", "did",
  "eurostat", "httr2", "jsonlite",
  "xtable", "sandwich", "lmtest",
  "fwildclusterboot", "ggplot2"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(fixest)
  library(did)
  library(eurostat)
  library(httr2)
  library(jsonlite)
  library(xtable)
  library(ggplot2)
})

cat("All packages loaded.\n")
