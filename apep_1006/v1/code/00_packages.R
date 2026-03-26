# 00_packages.R — Load required packages
# APEP 1006: Sovereign Stigma and the Price of Sending Money Home

pkgs <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects (TWFE robustness)
  "did",            # Callaway-Sant'Anna staggered DiD
  "ggplot2",        # Plotting (not used in V1 but needed for diagnostics)
  "readxl",         # Read Excel files (RPW dataset)
  "jsonlite",       # Write diagnostics.json
  "countrycode",    # ISO country code conversions
  "httr",           # HTTP downloads
  "WDI",            # World Development Indicators
  "sandwich",       # Robust SEs
  "lmtest",         # Coefficient tests
  "knitr",          # Table formatting
  "stringr"         # String manipulation
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
