# ==============================================================================
# 00_packages.R — Package Loading
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

required <- c("duckdb", "DBI", "data.table", "fixest", "modelsummary",
              "xtable", "jsonlite")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(duckdb)
library(DBI)
library(data.table)
library(fixest)
library(modelsummary)
library(jsonlite)

cat("All packages loaded.\n")
