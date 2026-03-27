# =============================================================================
# 00_packages.R — APEP 1073: BRAC Base Closures
# =============================================================================
library(duckdb)
library(DBI)
library(data.table)
library(fixest)
library(did)
library(ggplot2)
library(modelsummary)
library(kableExtra)
library(jsonlite)

if (!requireNamespace("HonestDiD", quietly = TRUE)) {
  install.packages("HonestDiD", repos = "https://cloud.r-project.org")
}
library(HonestDiD)

message("All packages loaded.")
