# 00_packages.R — Required packages for apep_1225
# Section 60 Stop-and-Search Relaxation and Knife Crime

required <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest",        # TWFE and event study
  "did",           # Callaway-Sant'Anna
  "ggplot2",
  "jsonlite",
  "httr",          # API calls to police.uk
  "sandwich", "lmtest",  # Robust SEs
  "fwildclusterboot",    # Wild cluster bootstrap
  "spdep",         # Spatial weights for displacement test
  "sf",            # Spatial data handling
  "xtable"         # LaTeX table output
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
