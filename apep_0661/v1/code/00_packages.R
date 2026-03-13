# 00_packages.R — Required packages for apep_0661
# UK Asylum Dispersal and Local Crime

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, IV)
  "modelsummary",  # Regression tables
  "ggplot2",       # Plotting (not used in V1 but for diagnostics)
  "httr",          # HTTP requests for APIs
  "jsonlite",      # JSON parsing
  "readxl",        # Excel file reading
  "writexl",       # Excel writing
  "kableExtra",    # Table formatting
  "sandwich",      # Robust standard errors
  "lmtest"         # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
