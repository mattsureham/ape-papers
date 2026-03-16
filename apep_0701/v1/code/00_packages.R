################################################################################
# 00_packages.R — Load and install required packages
# Paper: apep_0701 — FUNDEB Gender Effects
################################################################################

pkgs <- c(
  "tidyverse", "fixest", "did", "bigrquery", "DBI",
  "educabR", "jsonlite", "haven", "arrow", "readxl",
  "broom", "modelsummary", "kableExtra", "xtable",
  "scales", "lubridate", "glue", "data.table"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    message("Installing: ", p)
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
  library(did)
  library(bigrquery)
  library(DBI)
  library(educabR)
  library(jsonlite)
  library(haven)
  library(arrow)
  library(readxl)
  library(broom)
  library(modelsummary)
  library(kableExtra)
  library(xtable)
  library(scales)
  library(lubridate)
  library(glue)
  library(data.table)
})

cat("All packages loaded.\n")
