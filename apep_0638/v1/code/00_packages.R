## 00_packages.R — Saturday Soldier (apep_0638)
## Required packages for ENOE analysis

pkgs <- c("data.table", "fixest", "modelsummary", "jsonlite", "xtable")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
