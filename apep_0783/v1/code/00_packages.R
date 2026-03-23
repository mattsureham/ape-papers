## 00_packages.R — Load and install required packages
## apep_0783: USPS POStPlan and Rural Business Formation

required_packages <- c(
  "tidyverse",    # Data manipulation + visualization
  "fixest",       # High-dimensional fixed effects
  "did",          # Callaway-Sant'Anna staggered DiD
  "data.table",   # Fast data operations
  "readxl",       # Excel reading
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX tables
  "modelsummary", # Regression tables
  "sandwich",     # Robust SEs
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", packageVersion("fixest") |> as.character(), "\n")
cat("did version:", packageVersion("did") |> as.character(), "\n")
