## 00_packages.R — Install and load required packages
## APEP apep_0623: The Symmetric Tax Shock

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, sunab)
  "ggplot2",       # Plotting (for diagnostics only, no figures in V1)
  "readxl",        # Read Excel files (FHFA)
  "jsonlite",      # Write diagnostics.json
  "stargazer",     # Table formatting
  "modelsummary",  # Alternative table formatting
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient testing
  "car",           # Linear hypothesis testing (symmetry test)
  "kableExtra",    # LaTeX table generation
  "curl"           # Data downloads
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("data.table version:", as.character(packageVersion("data.table")), "\n")
