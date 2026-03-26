## 00_packages.R — Install and load required packages
## apep_1025: Residential Neonicotinoid Bans and Bird Populations

required_pkgs <- c(
  "data.table", "fixest", "did", "ggplot2",
  "jsonlite", "dplyr", "tidyr", "stringr",
  "fwildclusterboot", "kableExtra", "modelsummary"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
