# 00_packages.R — Package loading for apep_1029
# UK Companies Act multi-threshold bunching

required_packages <- c(
  "tidyverse",   # Data manipulation + ggplot2
  "data.table",  # Fast data operations
  "httr",        # HTTP requests for Companies House API
  "jsonlite",    # JSON parsing
  "fixest",      # Fixed effects estimation
  "xtable",      # LaTeX table output
  "boot",        # Bootstrap inference
  "scales",      # Axis formatting
  "zoo"          # Rolling calculations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
