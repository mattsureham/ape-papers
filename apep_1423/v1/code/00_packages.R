# 00_packages.R — Package loading for apep_1423
# Watershed boundary DiD: CWA 303(d) listing and facility discharges

required_packages <- c(
  "data.table",     # Fast data manipulation
  "httr",           # API calls
  "jsonlite",       # JSON parsing
  "fixest",         # High-dimensional fixed effects
  "did",            # Callaway-Sant'Anna estimator
  "ggplot2",        # Plotting (not used in V1 tables-only)
  "kableExtra",     # Table formatting
  "sf",             # Spatial operations
  "stringr",        # String manipulation
  "lubridate"       # Date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
