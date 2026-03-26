# 00_packages.R — Load required libraries
# apep_1024: France DPE Rental Ban Bunching

required_packages <- c(
  "data.table",    # Fast data manipulation
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "fixest",        # Fixed effects regressions
  "ggplot2",       # (not used for V1, but needed by bunching code)
  "sandwich",      # Robust SEs
  "lmtest",        # Hypothesis testing
  "stargazer",     # Table output
  "xtable"         # LaTeX table generation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
