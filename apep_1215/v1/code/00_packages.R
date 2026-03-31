# 00_packages.R — Load required packages for apep_1215
# "Does Cheaper Transit Unlock Jobs? The Deutschlandticket and Regional Labor Markets"

required_packages <- c(
  "tidyverse",     # data wrangling + ggplot2
  "fixest",        # fast fixed effects estimation
  "eurostat",      # Eurostat API access
  "jsonlite",      # diagnostics output
  "xtable",        # LaTeX table generation
  "sandwich",      # robust standard errors
  "lmtest"         # coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
