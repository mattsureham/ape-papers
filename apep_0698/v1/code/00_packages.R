# 00_packages.R — Load and install required packages
# PPP Nonprofit Employment RDD (apep_0698)

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "data.table",   # fast CSV reading
  "fixest",       # fixed effects regression
  "rdrobust",     # RDD estimation (CCT bandwidth, local polynomial)
  "rddensity",    # McCrary-style manipulation test
  "modelsummary", # regression tables
  "xtable",       # LaTeX table output
  "jsonlite",     # diagnostics.json output
  "stringdist"    # fuzzy name matching
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
