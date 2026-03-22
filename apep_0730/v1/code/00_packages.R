# 00_packages.R — Required packages for apep_0730
# Time Zone Boundaries and Teen Morning Traffic Deaths

required <- c(
  "tidyverse",     # data manipulation + ggplot2
  "data.table",    # fast I/O
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "sf",            # spatial data
  "rdrobust",      # RDD estimation
  "rddensity",     # McCrary density test
  "fixest",        # fast fixed effects
  "modelsummary",  # table output
  "xtable",        # LaTeX tables
  "sandwich",      # robust SEs
  "lmtest"         # coefficient tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
