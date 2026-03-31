# 00_packages.R — Install and load required packages
pkgs <- c("data.table", "fixest", "did", "ggplot2", "httr", "jsonlite",
          "readxl", "pxR", "stringr", "modelsummary", "kableExtra",
          "sandwich", "lmtest", "haven")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
