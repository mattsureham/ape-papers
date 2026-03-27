# 00_packages.R — Load and install required packages
pkgs <- c("tidyverse", "fixest", "data.table", "httr", "jsonlite",
          "rdrobust", "rddensity", "modelsummary", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
