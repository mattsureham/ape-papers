## 00_packages.R — Load required packages for bunching analysis
## apep_0727: German Solar PV Bunching at 10 kWp Threshold

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects regressions
  "xtable",        # LaTeX table generation
  "jsonlite",      # JSON output
  "boot",          # Bootstrap inference
  "stats"          # Polynomial fitting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
