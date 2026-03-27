# 00_packages.R — Load and install required packages
# The Phantom Pollution Drop: TRI Reporting Rule Changes and Apparent Emissions Declines

required_packages <- c(
  "data.table",    # Fast data manipulation
  "httr",          # HTTP requests for EPA API
  "jsonlite",      # JSON parsing
  "fixest",        # Fixed effects estimation (feols)
  "did",           # Callaway & Sant'Anna (2021) DiD
  "xtable",        # LaTeX table output
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
