## 00_packages.R — Load required libraries
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

required <- c(
  "httr", "jsonlite", "readxl",    # Data fetching
  "dplyr", "tidyr", "stringr",     # Data wrangling
  "fixest",                         # DiD estimation
  "did",                            # Callaway-Sant'Anna
  "modelsummary",                   # Tables
  "xtable",                         # LaTeX tables
  "here"                            # Project paths
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
