# ============================================================
# 00_packages.R — Install and load required packages
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

required_packages <- c(
  "tidyverse",      # Data manipulation and visualization

"fixest",         # Fast fixed effects estimation
  "did",            # Callaway-Sant'Anna staggered DiD
  "data.table",     # Fast data I/O
  "httr",           # HTTP requests for API data
  "jsonlite",       # JSON parsing
  "lubridate",      # Date handling
  "xtable",         # LaTeX table generation
  "kableExtra",     # Additional table formatting
  "bacondecomp"     # Goodman-Bacon decomposition
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
