# 00_packages.R — Load required packages for apep_0887
# Radon building codes as behavioral nudges

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, sunab)
  "did",           # Callaway & Sant'Anna DiD
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "readr",         # CSV reading
  "dplyr",         # Data wrangling
  "tidyr",         # Data reshaping
  "stringr",       # String operations
  "ggplot2",       # Plotting (not used in V1 but needed by did package)
  "sandwich",      # Robust SEs
  "lmtest",        # Coefficient tests
  "fwildclusterboot" # Wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
