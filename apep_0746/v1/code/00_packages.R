## 00_packages.R — Load and install required packages
## APEP-0746: REP School Boundary RDD on Housing Prices in France

required <- c(
  "data.table",    # Fast data manipulation

"sf",            # Spatial operations
  "rdrobust",      # RDD estimation (CCT bandwidth, robust bias-corrected inference)
  "rddensity",     # McCrary density test
  "fixest",        # High-dimensional FE regressions
  "ggplot2",       # Plotting (not used for V1 tables-only, but for diagnostics)
  "jsonlite",      # Write diagnostics.json
  "stargazer",     # LaTeX table output
  "kableExtra",    # Additional table formatting
  "units"          # Handle sf units
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
