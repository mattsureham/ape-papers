# 00_packages.R — Install and load required packages
# Uses: fixest for regressions, data.table for panel construction
pkgs <- c("data.table", "fixest", "httr", "jsonlite", "readr", "stringr")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

if (!dir.exists("data")) dir.create("data", recursive = TRUE)
if (!dir.exists("tables")) dir.create("tables", recursive = TRUE)

cat("Packages loaded. Working directory:", getwd(), "\n")
