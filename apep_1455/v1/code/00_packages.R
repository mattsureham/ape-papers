# 00_packages.R — Install and load required packages
required <- c("tidyverse", "fixest", "did", "readxl", "httr", "jsonlite", "data.table")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}
cat("All packages loaded.\n")
