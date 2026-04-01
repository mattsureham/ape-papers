## 00_packages.R — Load required libraries
## apep_1241: Animal Welfare Havens

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fixed effects estimation
  "did",          # Callaway-Sant'Anna
  "httr2",        # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # robust/clustered SEs
  "modelsummary", # regression tables
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
