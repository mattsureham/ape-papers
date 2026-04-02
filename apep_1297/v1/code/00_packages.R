# 00_packages.R — Load and install required packages
# Ireland HTB Price Bunching (apep_1297)

required <- c(
  "tidyverse",   # data wrangling + ggplot2

"fixest",       # regression with clustered SEs
  "data.table",  # fast data ops
  "jsonlite",    # diagnostics.json output
  "xtable",      # LaTeX table generation
  "boot"         # bootstrap inference
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
