## 00_packages.R — Install/load required packages
## Paper: apep_0690 — UK Office-to-Residential PD Rights

pkgs <- c(
  "data.table", "readODS", "httr2", "jsonlite", "fixest",
  "modelsummary", "kableExtra", "ggplot2", "did", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
