## 00_packages.R — Package management for apep_0727 v2
## German Solar PV Bunching at 10 kWp Threshold (Revision)

required_packages <- c(
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects (for heterogeneity regressions)
  "ggplot2",      # Figures (V2 requirement)
  "scales",       # ggplot2 axis formatting
  "viridis",      # Color palettes
  "jsonlite",     # JSON I/O
  "xtable",       # LaTeX tables
  "knitr",        # Table formatting
  "boot",         # Bootstrap inference
  "stats"         # Polynomial fitting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Set global options
options(scipen = 999)  # Avoid scientific notation
cat("Packages loaded.\n")
