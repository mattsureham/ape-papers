# 00_packages.R — Load and install required packages
# apep_1079: Section 301 tariffs and racial employment effects

pkgs <- c("tidyverse", "fixest", "data.table", "arrow", "duckdb", "DBI",
          "httr", "jsonlite", "modelsummary", "kableExtra")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("duckdb version:", as.character(packageVersion("duckdb")), "\n")
