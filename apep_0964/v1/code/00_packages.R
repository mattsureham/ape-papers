# 00_packages.R — Load required libraries for ATAD analysis
# Install if needed
for (pkg in c("eurostat", "data.table", "fixest", "modelsummary",
              "xtable", "jsonlite", "fwildclusterboot", "did")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(eurostat)
library(data.table)
library(fixest)
library(modelsummary)
library(xtable)
library(jsonlite)
library(fwildclusterboot)
