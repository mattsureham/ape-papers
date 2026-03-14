## 00_packages.R — Load required packages
## apep_0675: Carbon Tax Pass-Through and Gas Demand Elasticity

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "eurostat",     # Eurostat API
  "fixest",       # fast fixed-effects IV
  "did",          # Callaway-Sant'Anna
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics output
  "xtable"        # LaTeX tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
