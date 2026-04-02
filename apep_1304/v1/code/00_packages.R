# 00_packages.R — Package dependencies for apep_1299
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

required_packages <- c(
  "data.table",       # Fast data manipulation
  "arrow",            # Parquet file reading
  "fixest",           # IV/2SLS with fixed effects (feols)
  "xtable",           # LaTeX table output
  "jsonlite",         # diagnostics.json output
  "httr",             # World Bank API calls
  "sandwich",         # Robust standard errors
  "lmtest",           # Coefficient testing
  "fwildclusterboot", # Wild cluster bootstrap
  "modelsummary",     # Regression tables
  "kableExtra"        # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
