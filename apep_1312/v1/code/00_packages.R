# 00_packages.R — Load required packages for apep_1312
# North Macedonia progressive tax experiment

required_packages <- c(
  "httr", "jsonlite",      # API access
  "data.table",            # Data manipulation
  "fixest",                # Two-way FE regressions
  "ggplot2",               # (Not used for V1 but needed for diagnostics)
  "sandwich", "lmtest",    # Robust SEs
  "boot",                  # Bootstrap
  "xtable",                # LaTeX tables
  "knitr"                  # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
