## ── 00_packages.R ──────────────────────────────────────────────────
## Install and load required packages for apep_1294
## ST reservation rotation and deforestation in India
## ────────────────────────────────────────────────────────────────────

required <- c(
  "data.table",   # Fast data manipulation
  "fixest",       # Two-way FE, event studies
  "modelsummary", # Regression tables
  "xtable",       # LaTeX table export
  "jsonlite",     # diagnostics.json output
  "httr",         # HTTP downloads
  "stringr"       # String manipulation
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
