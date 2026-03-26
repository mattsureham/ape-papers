# 00_packages.R — Required packages for IR35 bunching analysis
# apep_0999

required_packages <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects estimation
  "ggplot2",        # Plotting (for diagnostics only, V1 has no figures)
  "httr",           # API calls
  "jsonlite",       # JSON parsing
  "sandwich",       # Robust SEs
  "boot",           # Bootstrap inference
  "xtable",         # LaTeX table generation
  "stringr"         # String manipulation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
