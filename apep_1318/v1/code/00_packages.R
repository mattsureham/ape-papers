# 00_packages.R — Load required packages
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

pkgs <- c(
  "eurostat",     # Eurostat data access
  "httr",         # HTTP requests (World Bank API)
  "jsonlite",     # JSON parsing
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects estimation (feols)
  "did",          # Callaway-Sant'Anna staggered DiD
  "ggplot2",      # Plotting (for diagnostics only)
  "sandwich",     # Robust SEs
  "lmtest",       # Coefficient testing
  "boot",             # Bootstrap methods
  "modelsummary", # Table generation
  "kableExtra",   # LaTeX tables
  "xtable"        # LaTeX table export
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
