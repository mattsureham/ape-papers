# 00_packages.R — apep_1239: Swiss NFA Reform
# Install and load required packages

required_packages <- c(
  "tidyverse",    # Data wrangling + plotting
  "fixest",       # Two-way fixed effects, event studies
  "httr",         # HTTP requests for BFS PXWeb API
  "jsonlite",     # JSON parsing
  "data.table",   # Efficient data manipulation
  "xtable",       # LaTeX table generation
  "kableExtra",   # Enhanced tables
  "sandwich",     # Robust SEs
  "lmtest"        # Coefficient tests
)

# fwildclusterboot may not be available for this R version
# We'll use fixest's built-in cluster bootstrap or manual RI instead
tryCatch({
  if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
    install.packages("fwildclusterboot", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(fwildclusterboot)
  cat("fwildclusterboot loaded.\n")
}, error = function(e) {
  cat("fwildclusterboot not available; will use fixest cluster SEs + manual RI.\n")
})

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
