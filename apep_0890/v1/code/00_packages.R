# 00_packages.R — Package installation and loading
# apep_0890: Craigslist Entry and Local Journalism Employment

required_packages <- c(
  "tidyverse", "fixest", "did", "data.table", "duckdb", "DBI",
  "jsonlite", "xtable", "HonestDiD", "modelsummary"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
