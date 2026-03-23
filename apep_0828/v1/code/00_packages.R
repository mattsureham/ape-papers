## 00_packages.R — Install and load required packages for apep_0828
## Smart Motorway Conversions and Road Safety

required_packages <- c(
  "stats19",        # DfT STATS19 collision data
  "did",            # Callaway-Sant'Anna estimator
  "fixest",         # Sun-Abraham (sunab), fast FE regressions
  "data.table",     # Memory-efficient data manipulation
  "sf",             # Spatial operations (geocoding collisions to sections)
  "dplyr",          # Data manipulation
  "tidyr",          # Reshaping
  "ggplot2",        # Plotting (for diagnostics, not paper figures)
  "lubridate",      # Date handling
  "jsonlite",       # JSON output for diagnostics
  "sandwich",       # Robust SEs
  "lmtest",         # Coefficient tests
  "HonestDiD",      # Rambachan-Roth sensitivity
  "fwildclusterboot", # Wild cluster bootstrap
  "xtable"          # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
