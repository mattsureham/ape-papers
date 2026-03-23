## 00_packages.R — Install and load required packages
pkgs <- c("httr", "jsonlite", "dplyr", "tidyr", "fixest", "ggplot2",
          "modelsummary", "kableExtra", "data.table", "stringr", "purrr")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)
library(modelsummary)
library(kableExtra)
library(data.table)
library(stringr)
library(purrr)
cat("All packages loaded.\n")
