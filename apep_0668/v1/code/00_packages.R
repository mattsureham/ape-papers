## 00_packages.R — Install and load required packages
## apep_0668: The Pollinator Penalty

pkgs <- c(
  "eurostat",    # Eurostat API
  "dplyr",       # Data manipulation
  "tidyr",       # Reshaping
  "stringr",     # String operations
  "fixest",      # Fixed effects estimation (feols)
  "modelsummary", # Table output
  "ggplot2",     # Plotting (for diagnostics only, no paper figures)
  "jsonlite",    # JSON output for diagnostics
  "kableExtra",  # Table formatting
  "xtable"       # LaTeX table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
