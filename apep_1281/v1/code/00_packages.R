## 00_packages.R — Load and install required packages
## apep_1281: Pricing to the Cap

pkgs <- c("data.table", "fixest", "ggplot2", "jsonlite", "xtable", "boot")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
