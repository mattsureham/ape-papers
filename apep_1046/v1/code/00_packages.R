## 00_packages.R — Load required libraries
## apep_1046: Cross-hazard injury substitution from OSHA silica standard

required <- c(
  "data.table", "fixest", "ggplot2", "modelsummary",
  "jsonlite", "xtable", "stringr", "curl"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
