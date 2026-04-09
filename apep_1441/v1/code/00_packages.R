# 00_packages.R — Load required libraries
# APEP-1441: Swiss cantonal minimum wages

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects (feols, sunab)
  "did",          # Callaway & Sant'Anna
  "HonestDiD",    # sensitivity analysis for parallel trends
  "data.table",   # fast data ops
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX tables
  "sandwich",     # robust SEs
  "lmtest",       # coefficient tests
  "bacondecomp"   # Bacon decomposition for TWFE diagnostics
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
