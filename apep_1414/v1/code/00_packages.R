## 00_packages.R — Install and load required packages
## apep_1414: UK MOT First-Inspection RDD

packages <- c(
  "duckdb",
  "tidyverse",
  "rdrobust",
  "rddensity",
  "jsonlite",
  "arrow",
  "lubridate",
  "knitr",
  "kableExtra",
  "fixest",
  "modelsummary"
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(duckdb)
  library(tidyverse)
  library(rdrobust)
  library(rddensity)
  library(jsonlite)
  library(arrow)
  library(lubridate)
  library(knitr)
  library(kableExtra)
  library(fixest)
  library(modelsummary)
})

cat("All packages loaded successfully.\n")
