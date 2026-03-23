## 00_packages.R — Load and install required packages
## apep_0824: Romania micro-enterprise threshold bunching

required_pkgs <- c(
  "tidyverse",    # data manipulation + plotting
  "eurostat",     # Eurostat data API
  "fixest",       # fast fixed effects
  "data.table",   # efficient data operations
  "jsonlite",     # diagnostics output
  "xtable",       # LaTeX table generation
  "sandwich",     # robust SEs
  "boot"          # bootstrap inference
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
