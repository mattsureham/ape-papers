# =============================================================================
# 00_packages.R — Load required libraries
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

required_packages <- c(
  "tidyverse",   # Data manipulation + ggplot2

"fixest",      # TWFE, Sun-Abraham
  "did",         # Callaway-Sant'Anna
  "HonestDiD",   # Rambachan-Roth sensitivity
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "data.table",  # Fast data operations
  "latex2exp",   # LaTeX in plots
  "kableExtra",  # LaTeX tables
  "xtable",      # Additional table formatting
  "sf",          # Spatial data for maps
  "scales",      # Axis formatting
  "patchwork"    # Multi-panel figures
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
