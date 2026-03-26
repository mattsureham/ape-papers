## 00_packages.R — Load required packages
## apep_0976: Yakuza Exclusion Ordinances and Real Estate Markets

required_packages <- c(
  "tidyverse",   # Data manipulation and visualization
  "fixest",      # Fixed effects estimation (TWFE, Sun-Abraham)
  "did",         # Callaway-Sant'Anna DiD estimator
  "httr",        # HTTP requests (e-Stat API)
  "jsonlite",    # JSON parsing
  "xtable",      # LaTeX table generation
  "knitr",       # Additional formatting
  "sandwich",    # Robust variance estimators
  "lmtest"       # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
