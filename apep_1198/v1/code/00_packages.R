## 00_packages.R — Package loading for apep_1198
## UK FIT Solar Bunching (Triple-Threshold Design)

required_packages <- c(
  "data.table",   # Data manipulation
  "readxl",       # Read Ofgem XLSX files
  "ggplot2",      # Figures (not used in V1 tables, but for diagnostics)
  "fixest",       # Not needed for bunching, but for any regression
  "kableExtra",   # Table generation
  "jsonlite",     # diagnostics.json output
  "boot"          # Bootstrap inference
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
