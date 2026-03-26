# 00_packages.R — Install and load required packages
# apep_1017: EU Fourth Railway Package and Rail Fares

required <- c(
  "data.table", "dplyr", "tidyr", "eurostat", "fixest", "did",
  "ggplot2", "httr2", "jsonlite", "sandwich", "lmtest",
  "fwildclusterboot", "kableExtra", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(eurostat)
  library(fixest)
  library(did)
  library(ggplot2)
  library(httr2)
  library(jsonlite)
  library(sandwich)
  library(lmtest)
  library(fwildclusterboot)
  library(kableExtra)
  library(xtable)
})

message("All packages loaded successfully.")
