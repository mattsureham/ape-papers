# 00_packages.R — Load required packages for apep_0943
# Swiss CO2 Act referendum and subnational decarbonization

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "httr",          # HTTP requests for BFS API
  "jsonlite",      # JSON parsing
  "xtable",        # LaTeX table output
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
