## 00_packages.R — Load required libraries
## apep_1143: Solar PV and Farmland Birds

required_packages <- c(
  "data.table",     # Memory-efficient data manipulation
  "did",            # Callaway-Sant'Anna staggered DiD
  "fixest",         # TWFE, Sun-Abraham, PPML
  "HonestDiD",      # Sensitivity analysis
  "sf",             # Spatial operations (distances)
  "jsonlite",       # JSON I/O
  "httr"            # HTTP downloads
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
