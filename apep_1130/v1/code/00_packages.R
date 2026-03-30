## 00_packages.R — Load required libraries
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

required_pkgs <- c(
  "data.table", "fixest", "did", "httr2", "jsonlite",
  "ggplot2", "xtable", "modelsummary", "sandwich", "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
