## 00_packages.R — Install and load required packages
## apep_0993: South Korea 52-Hour Workweek Reform
## Uses: fixest, did, data.table (standard econometrics stack)

required_packages <- c(
  "jsonlite",      # JSON handling
  "data.table",    # Fast data manipulation
  "fixest",        # Fast fixed effects estimation
  "did",           # Callaway-Sant'Anna DiD
  "modelsummary",  # Table generation
  "kableExtra",    # LaTeX table formatting
  "xtable",        # LaTeX tables
  "sandwich",      # Robust standard errors
  "lmtest",        # Hypothesis tests
  "httr",          # HTTP requests for APIs
  "curl"           # URL handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
