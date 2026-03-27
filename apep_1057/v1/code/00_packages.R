# 00_packages.R — Load required packages
# apep_1057: The Consolidation Trap

required_packages <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fast fixed effects (feols, TWFE baseline)
  "did",         # Callaway & Sant'Anna (2021) staggered DiD
  "data.table",  # memory-efficient large data operations
  "jsonlite",    # read/write JSON (diagnostics, API responses)
  "httr",        # HTTP requests to EPA API
  "sandwich",    # robust SEs
  "lmtest",      # coeftest
  "modelsummary",# regression tables
  "kableExtra"   # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
