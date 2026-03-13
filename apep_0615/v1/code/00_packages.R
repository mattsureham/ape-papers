# 00_packages.R — Load required packages for apep_0615
# Drug Price Transparency and Strategic Threshold Avoidance

required_pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fixed effects regression
  "data.table",   # fast data operations
  "jsonlite",     # JSON API parsing
  "httr",         # HTTP requests
  "boot",         # bootstrap inference
  "xtable",       # LaTeX table output
  "knitr",        # table formatting
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient testing
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
