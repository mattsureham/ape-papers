## 00_packages.R — Load required libraries
## APEP-1174: The Enforcement Lottery

pkgs <- c(
  "data.table", "fixest", "httr", "jsonlite",
  "modelsummary", "kableExtra", "xtable"
)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}

library(data.table)
library(fixest)
library(httr)
library(jsonlite)
library(modelsummary)
library(kableExtra)
library(xtable)

cat("All packages loaded.\n")
