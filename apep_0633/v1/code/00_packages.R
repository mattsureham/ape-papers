## 00_packages.R — Load and install required packages
## apep_0633: Marijuana tax earmarking and education spending fungibility

required_packages <- c(
  "tidyverse",    # data manipulation
  "readxl",       # read Excel files
  "httr",         # HTTP requests for data download
  "did",          # Callaway-Sant'Anna DiD
  "fixest",       # fast fixed effects (TWFE comparison)
  "modelsummary", # table generation
  "kableExtra",   # LaTeX table formatting
  "jsonlite"      # diagnostics output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
