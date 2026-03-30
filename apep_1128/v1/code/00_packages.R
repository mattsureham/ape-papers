## 00_packages.R — Install and load required packages
pkgs <- c("data.table", "fixest", "arrow", "jsonlite", "xtable", "fwildclusterboot", "did")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}
library(data.table)
library(fixest)
library(arrow)
library(jsonlite)
library(xtable)
library(fwildclusterboot)
library(did)
cat("All packages loaded.\n")
