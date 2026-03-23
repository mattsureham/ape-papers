## 00_packages.R — Load and install required packages
## Paper: Carbon Border Deflection (apep_0788)

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects (feols, fepois)
  "data.table",   # Fast data operations
  "httr2",        # HTTP API calls
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX table generation
  "sandwich",     # Robust SEs
  "lmtest"        # Coefficient tests
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
