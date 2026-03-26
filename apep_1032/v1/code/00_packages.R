## 00_packages.R — Load required packages
## APEP-1032: The Deterrence Gap

pkgs <- c("tidyverse", "fixest", "httr", "jsonlite", "data.table",
          "sandwich", "lmtest", "kableExtra", "modelsummary")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
