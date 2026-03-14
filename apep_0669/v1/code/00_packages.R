## 00_packages.R — Load and install required packages
## APEP Paper apep_0669: Capitalization of Reproductive Rights

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "rdrobust",     # RDD estimation and inference
  "data.table",   # Fast data I/O
  "jsonlite",     # JSON output for diagnostics
  "httr",         # HTTP requests for data download
  "sf",           # Spatial operations
  "tigris",       # Census TIGER shapefiles
  "modelsummary", # Table output
  "kableExtra"    # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Set tigris options
options(tigris_use_cache = TRUE)
options(tigris_class = "sf")

cat("All packages loaded successfully.\n")
