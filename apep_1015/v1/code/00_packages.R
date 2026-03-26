# =============================================================================
# 00_packages.R — Install and load required packages
# apep_1015: The First Wage Floor for Women
# =============================================================================

pkgs <- c("duckdb", "arrow", "data.table", "fixest", "modelsummary",
          "xtable", "fwildclusterboot", "jsonlite")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
