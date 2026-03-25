# 00_packages.R — Load required packages
# apep_0961: Swiss tobacco billboard bans and healthcare costs

required <- c(
  "readxl",      # Read Excel files
  "data.table",  # Fast data manipulation
  "fixest",      # Fixed effects estimation
  "did",         # Callaway & Sant'Anna DiD
  "ggplot2",     # Plotting (not for paper, for diagnostics)
  "jsonlite",    # Write diagnostics.json
  "sandwich",    # Robust SEs
  "lmtest",      # Coefficient testing
  "fwildclusterboot", # Wild cluster bootstrap
  "HonestDiD"    # Sensitivity analysis
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
