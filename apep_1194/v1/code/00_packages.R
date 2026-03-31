# 00_packages.R — Load and install required packages
# APEP-1194: Positive Train Control and Railroad Accident Prevention

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "jsonlite",     # JSON parsing for Socrata API
  "httr",         # HTTP requests
  "data.table",   # Efficient data manipulation
  "bacondecomp",  # Goodman-Bacon decomposition
  "fwildclusterboot", # Wild cluster bootstrap
  "xtable",       # LaTeX table generation
  "kableExtra",   # Enhanced table formatting
  "sandwich",     # Robust SEs
  "lmtest"        # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
