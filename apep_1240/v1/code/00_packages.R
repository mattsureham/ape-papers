## ── 00_packages.R ──────────────────────────────────────────────
## Install and load required packages for CGWB groundwater analysis

pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr",
  "readr", "jsonlite", "stringr", "sf", "httr2",
  "did", "modelsummary", "xtable", "kableExtra"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
