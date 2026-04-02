## 00_packages.R — Load required packages for apep_1322
## State Zoning Preemption and Missing Middle Housing

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE and CS-style event study
  "did",          # Callaway-Sant'Anna
  "jsonlite",     # JSON I/O for diagnostics
  "httr",         # HTTP requests
  "readxl",       # Excel files
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "boot"              # bootstrap for RI
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
