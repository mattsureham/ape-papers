## 00_packages.R — Install and load required packages
## apep_1296: Lithuania i.SAF and VAT compliance

required_packages <- c(
  "eurostat",      # Eurostat API
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols)
  "modelsummary",  # Regression tables
  "xtable",        # LaTeX table output
  "jsonlite",      # JSON I/O
  "fwildclusterboot", # Wild cluster bootstrap
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
