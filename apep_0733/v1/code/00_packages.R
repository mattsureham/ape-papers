## 00_packages.R — Load required packages
## Paper: The Fortress Premium (apep_0733)

required_pkgs <- c(
  "data.table", "fixest", "ggplot2",       # Core analysis
  "httr", "jsonlite", "rjstat",            # API data fetch
  "modelsummary", "kableExtra",             # Tables
  "sandwich", "lmtest",                     # Robust SEs
  "did",                                    # Callaway-Sant'Anna (optional)
  "xtable"                                  # LaTeX table output
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
