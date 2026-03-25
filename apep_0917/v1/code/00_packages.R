# 00_packages.R — Load and install required packages
# APEP Working Paper apep_0917

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "readxl",
  "jsonlite", "xtable", "modelsummary", "kableExtra",
  "HonestDiD", "fwildclusterboot"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
