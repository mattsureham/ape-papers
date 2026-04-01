## 00_packages.R — Load required libraries
## apep_1262: SRU carence declarations and electoral backlash

pkgs <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "data.table",   # Fast data I/O
  "httr",         # HTTP requests for data.gouv.fr
  "jsonlite",     # JSON parsing
  "readxl",       # Excel file reading
  "stargazer",    # Table output (backup)
  "kableExtra",   # Table formatting
  "modelsummary"  # Regression tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
