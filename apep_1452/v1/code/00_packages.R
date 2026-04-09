## 00_packages.R — Install/load required packages
pkgs <- c("tidyverse", "fixest", "httr2", "jsonlite", "readxl", "modelsummary",
          "kableExtra", "sandwich", "lmtest")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
