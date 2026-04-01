# 00_packages.R — Install and load required packages
# Paper: The Growth Ceiling (apep_1264)

required_pkgs <- c(
  "httr", "jsonlite",   # API access
  "data.table",          # data manipulation
  "fixest",              # regressions with FE
  "ggplot2",             # plotting (for diagnostics only, no figures in V1)
  "sandwich", "lmtest",  # robust SEs
  "dplyr", "tidyr",      # tidy helpers
  "kableExtra",          # table formatting
  "xtable"               # LaTeX table output
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
