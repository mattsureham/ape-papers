# ==============================================================================
# 00_packages.R — Package Installation and Loading
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

pkgs <- c("tidyverse", "fixest", "data.table", "jsonlite", "eurostat", "httr")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

library(tidyverse)
library(fixest)
library(data.table)
library(jsonlite)
library(eurostat)
library(httr)

cat("All packages loaded successfully.\n")
