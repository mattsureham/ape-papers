## 00_packages.R — Load and install required packages
pkgs <- c("tidyverse", "fixest", "did", "arrow", "data.table",
          "modelsummary", "kableExtra", "jsonlite", "sandwich")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}
library(tidyverse)
library(fixest)
library(did)
library(arrow)
library(data.table)
library(modelsummary)
library(kableExtra)
library(jsonlite)
library(sandwich)
cat("All packages loaded.\n")
