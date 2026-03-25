# 00_packages.R — Load and install required packages
# apep_0920: MAID Laws and End-of-Life Medicare Spending

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

"fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "httr",         # HTTP requests for CMS data
  "jsonlite",     # JSON parsing
  "readr",        # CSV reading
  "fwildclusterboot", # wild cluster bootstrap
  "modelsummary", # table generation
  "kableExtra",   # table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
