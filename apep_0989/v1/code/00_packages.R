# 00_packages.R — Install and load required packages
# Czech EET and Business Dynamics (apep_0989)

required_packages <- c(
  "czso",          # Czech Statistical Office open data
  "eurostat",      # Eurostat data access
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (sunab, feols)
  "did",           # Callaway-Sant'Anna estimator
  "ggplot2",       # Plotting (for diagnostics only, not paper figures)
  "dplyr",         # Data wrangling
  "tidyr",         # Reshaping
  "stringr",       # String operations
  "jsonlite",      # JSON output for diagnostics
  "xtable",        # LaTeX table generation
  "HonestDiD",     # Sensitivity analysis for parallel trends
  "knitr",         # Table formatting
  "sandwich",      # Robust standard errors
  "lmtest"         # Coefficient testing
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
cat("did version:", as.character(packageVersion("did")), "\n")
