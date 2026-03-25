## ============================================================================
## 00_packages.R — APEP-0910: The Measurement Artifact of Crime
## Install and load all required packages
## ============================================================================

pkgs <- c(
  "tidyverse",     # Data manipulation and visualization
  "fixest",        # Fast fixed effects estimation
  "did",           # Callaway-Sant'Anna DiD
  "httr",          # HTTP requests for FBI API
  "jsonlite",      # JSON parsing
  "readxl",        # Read Excel files
  "HonestDiD",     # Rambachan-Roth sensitivity
  "modelsummary",  # Table generation
  "kableExtra",    # LaTeX table formatting
  "sandwich",      # Robust standard errors
  "data.table"     # Memory-efficient data operations
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
