## 00_packages.R — Install and load required packages
## apep_0877: Croatia 2013 Fiscalization

pkgs <- c(
  "eurostat",      # Eurostat data API
  "httr",          # HTTP requests
  "jsonlite",      # JSON parsing
  "dplyr",         # Data manipulation
  "tidyr",         # Data reshaping
  "ggplot2",       # (tables only in V1, but needed for internal checks)
  "fixest",        # Fast fixed effects estimation
  "did",           # Callaway-Sant'Anna
  "modelsummary",  # Table output
  "kableExtra",    # LaTeX table formatting
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient tests
  "boot"           # Bootstrap
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
