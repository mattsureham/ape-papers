# 00_packages.R — Load required packages for apep_1311
# Colombia SECOP e-procurement analysis

required_pkgs <- c(
  "tidyverse",    # data manipulation & visualization
  "data.table",   # fast data processing
  "fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "jsonlite",     # JSON parsing for Socrata API
  "httr",         # HTTP requests
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable"        # LaTeX table export
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
