# 00_packages.R — Load required libraries
# Ban the Box and the Black Employment Gap (apep_1012)

required_packages <- c(
  "duckdb", "arrow", "data.table", "fixest", "did",
  "ggplot2", "modelsummary", "kableExtra", "jsonlite",
  "fwildclusterboot", "bacondecomp"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

message("All packages loaded successfully.")
