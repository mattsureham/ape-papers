# =============================================================================
# 00_packages.R — Package dependencies for apep_1246
# =============================================================================

required <- c(
  "duckdb", "DBI", "arrow",           # Azure / data access
  "data.table", "fixest",             # Core panel analysis
  "did",                              # Callaway-Sant'Anna
  "ggplot2",                          # (not used for V1 figures, but did::ggdid uses it)
  "sandwich", "lmtest",              # Robust inference
  "fwildclusterboot",                # Wild cluster bootstrap
  "HonestDiD",                       # Sensitivity analysis
  "jsonlite",                        # diagnostics.json
  "xtable"                           # LaTeX table generation
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(data.table)
library(did)

cat("All packages loaded.\n")
