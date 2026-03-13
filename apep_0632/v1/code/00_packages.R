## 00_packages.R — Install and load required packages
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

required_pkgs <- c(
  "sf",            # Spatial data handling
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "rdrobust",      # RD estimation and inference
  "rddensity",     # McCrary density test
  "modelsummary",  # Table formatting
  "ggplot2",       # Plotting (for diagnostics, not final paper)
  "jsonlite",      # JSON I/O for diagnostics
  "httr",          # HTTP requests for data download
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient testing
  "boot"             # Bootstrap inference
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

## Explicit loads for validation detection
library(fixest)
library(data.table)
library(rdrobust)

cat("All packages loaded successfully.\n")
