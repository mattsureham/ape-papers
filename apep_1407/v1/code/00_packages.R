## 00_packages.R — Load and install required packages
## apep_1407: The Insurance Denominator

pkgs <- c("tidyverse", "fixest", "data.table", "jsonlite", "httr2",
          "ggplot2", "scales", "kableExtra", "modelsummary", "broom")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
