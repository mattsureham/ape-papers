## 00_packages.R — Install and load required packages
## APEP Paper apep_0927: Japan Equal Pay Act

required_packages <- c(
  "tidyverse",     # Data manipulation + plotting
  "fixest",        # Fixed effects regression
  "did",           # Callaway-Sant'Anna DiD
  "readxl",        # Excel file reading
  "writexl",       # Excel output
  "xtable",        # LaTeX tables
  "jsonlite",      # JSON output
  "kableExtra",    # Table formatting
  "modelsummary",  # Regression tables
  "HonestDiD"      # Rambachan-Roth sensitivity
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
