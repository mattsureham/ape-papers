## 00_packages.R — Load required packages
## apep_0851: Abolishing the Tax Haven Next Door

pkgs <- c("tidyverse", "fixest", "eurostat", "jsonlite", "httr",
          "modelsummary", "kableExtra", "sandwich")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
