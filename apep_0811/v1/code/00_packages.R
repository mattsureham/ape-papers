# 00_packages.R — Install and load required packages for apep_0811
# UK Calorie Labeling and Restaurant Entry (Triple-DiD)

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, fepois)
  "ggplot2",       # Plotting (for diagnostics only — no figures in V1)
  "lubridate",     # Date handling
  "jsonlite",      # Write diagnostics.json
  "httr",          # HTTP downloads
  "stringr"        # String operations
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
