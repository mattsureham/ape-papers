## ── 00_packages.R ─────────────────────────────────────────────────────────
## Install and load required packages for RTW racial earnings gap analysis
## ───────────────────────────────────────────────────────────────────────────

required <- c(
  "tidyverse", "fixest", "did", "data.table", "arrow",
  "DBI", "duckdb", "jsonlite", "knitr", "modelsummary",
  "kableExtra", "fwildclusterboot", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
