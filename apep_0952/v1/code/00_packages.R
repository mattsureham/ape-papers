## 00_packages.R — Install and load required packages
## apep_0952: Australian Stamp Duty Threshold Bunching

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "ggplot2",       # Plotting (not for V1 figures, but for internal diagnostics)
  "xtable",        # LaTeX table generation
  "jsonlite",      # Write diagnostics.json
  "stringr",       # String manipulation
  "lubridate"      # Date handling
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
