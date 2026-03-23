# ==============================================================================
# 00_packages.R — Package Installation and Loading
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

# Install missing packages
pkgs <- c("tidyverse", "fixest", "did", "data.table", "duckdb", "DBI",
          "jsonlite", "xtable", "HonestDiD", "sandwich", "lmtest")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

library(tidyverse)
library(fixest)
library(did)
library(data.table)
library(duckdb)
library(DBI)
library(jsonlite)
library(xtable)
library(HonestDiD)
library(sandwich)
library(lmtest)

cat("All packages loaded successfully.\n")
