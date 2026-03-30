## 00_packages.R — Install and load required packages
## apep_1169: Click to Incorporate

required_pkgs <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fixed effects estimation, Sun-Abraham
  "did",          # Callaway-Sant'Anna DiD
  "fredr",        # FRED API access
  "jsonlite",     # JSON output
  "xtable",       # LaTeX table generation
  "sandwich",     # robust standard errors
  "bacondecomp",  # Goodman-Bacon decomposition
  "HonestDiD"     # Rambachan-Roth sensitivity analysis
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
