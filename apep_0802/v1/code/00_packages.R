## 00_packages.R — Load required packages for NZ deductibility analysis
## apep_0802

pkgs <- c("data.table", "fixest", "ggplot2", "jsonlite", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
