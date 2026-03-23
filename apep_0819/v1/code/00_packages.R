# 00_packages.R — Install and load required packages
# apep_0819: Media salience and disaster recovery in India

required <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation + IV
  "bigrquery",     # Google BigQuery access (GDELT)
  "ggplot2",       # Plotting (not used in V1 but for diagnostics)
  "modelsummary",  # Table generation
  "kableExtra",    # LaTeX table formatting
  "jsonlite",      # Write diagnostics.json
  "sandwich",      # Robust SEs
  "lmtest",        # Coefficient tests
  "boot"             # Bootstrap inference
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
