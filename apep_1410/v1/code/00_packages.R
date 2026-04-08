# 00_packages.R — Required packages for apep_1410
# BVG Conversion Rate and Capital Withdrawal Choice

pkgs <- c(
  "httr", "jsonlite",     # API access
  "data.table",           # Data manipulation
  "fixest",               # Econometrics (feols)
  "ggplot2", "scales",    # Visualization
  "patchwork",            # Figure composition
  "kableExtra",           # Table formatting
  "xtable",               # LaTeX tables
  "sandwich", "lmtest"    # Robust inference
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
