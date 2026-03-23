## 00_packages.R — Install and load required packages
## apep_0823: The Alice Dividend

pkgs <- c(
  "data.table", "fixest", "DBI", "duckdb",
  "modelsummary", "kableExtra", "jsonlite",
  "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
