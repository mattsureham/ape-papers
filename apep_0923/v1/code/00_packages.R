## 00_packages.R — Install and load required packages
## APEP-0923: The End of Banking Secrecy

required_pkgs <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did",          # Econometrics: TWFE + Callaway-Sant'Anna
  "ggplot2", "modelsummary", # Tables and figures
  "jsonlite", "httr",       # API access
  "sandwich", "lmtest",     # Robust SEs
  "fwildclusterboot"        # Wild cluster bootstrap
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
