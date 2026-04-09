# 00_packages.R — HACRP RDD packages
# Install/load required packages

pkgs <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "purrr",
  "fixest",       # fixed effects, clustering
  "rdrobust",     # RDD estimation (CCT 2014)
  "rddensity",    # McCrary density test
  "ggplot2",      # plotting (not used in V1 but needed for diagnostics)
  "jsonlite",     # diagnostics output
  "xtable",       # LaTeX tables
  "kableExtra"    # table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
