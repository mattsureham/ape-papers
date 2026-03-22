## 00_packages.R — Install and load required packages
## APEP-0739: GP Practice Closures and A&E Utilization

pkgs <- c(
  "data.table", "fixest", "did", "HonestDiD",
  "httr2", "jsonlite", "readxl",
  "ggplot2", "modelsummary", "xtable",
  "sf", "geosphere"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
