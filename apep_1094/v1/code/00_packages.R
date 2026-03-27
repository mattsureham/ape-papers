# =============================================================================
# 00_packages.R — Package installation and loading
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

needed <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects + clustering
  "did",          # Callaway-Sant'Anna staggered DiD
  "httr",         # HTTP requests for Census API
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "data.table"    # memory-efficient operations
)

for (pkg in needed) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
