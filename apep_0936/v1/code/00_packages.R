# 00_packages.R — Install and load required packages

pkgs <- c(
  "data.table", "dplyr", "tidyr", "stringr",
  "eurostat", "httr2", "jsonlite",
  "fixest", "did", "sandwich", "lmtest",
  "fwildclusterboot",
  "ggplot2", "xtable",
  "modelsummary"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(fixest)
  library(did)
  library(ggplot2)
  library(jsonlite)
})

message("All packages loaded.")
