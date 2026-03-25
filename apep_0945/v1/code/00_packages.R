## 00_packages.R — Install and load required packages for apep_0945
pkgs <- c("httr2", "jsonlite", "data.table", "fixest", "modelsummary",
          "xtable", "lubridate")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}
library(data.table)
library(fixest)
library(modelsummary)
library(lubridate)
library(jsonlite)
library(httr2)
cat("All packages loaded.\n")
