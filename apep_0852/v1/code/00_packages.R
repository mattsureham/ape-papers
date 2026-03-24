## 00_packages.R — Load required libraries for apep_0852
## Universal Free School Meals and Household Food Security

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects (feols)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # fast I/O
  "haven",        # read SAS/Stata files
  "jsonlite",     # diagnostics.json
  "kableExtra",   # table formatting (optional)
  "sandwich",     # robust SE
  "lmtest",       # coeftest
  "xtable"        # LaTeX tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
