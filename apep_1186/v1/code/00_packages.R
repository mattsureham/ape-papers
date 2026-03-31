## 00_packages.R — Load required libraries
## apep_1186: Railroad Quiet Zones and Crossing Safety

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fast fixed effects estimation (feols, fepois)
  "did",           # Callaway-Sant'Anna staggered DiD
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "modelsummary",  # Table generation
  "kableExtra",    # LaTeX table formatting
  "ggplot2"        # (for diagnostics only — V1 has no figures)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
