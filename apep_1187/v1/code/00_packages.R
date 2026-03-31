# =============================================================================
# 00_packages.R — Package installation and loading
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

required_packages <- c(
  "httr", "jsonlite", "pxweb",     # SCB API access
  "data.table", "dplyr", "tidyr",  # Data manipulation
  "fixest",                         # Fast fixed effects (feols, feglm)
  "rdrobust",                       # RDD estimation (CCT bandwidth)
  "rddensity",                      # McCrary density test
  "did",                            # Callaway-Sant'Anna DiD
  "sandwich", "lmtest",            # Robust SE
  "xtable", "stargazer",           # Table output
  "ggplot2",                        # (for diagnostics only, not paper figures)
  "modelsummary"                    # Publication-quality tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
