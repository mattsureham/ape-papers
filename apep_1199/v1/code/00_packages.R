# ─────────────────────────────────────────────
# 00_packages.R — Install and load required packages
# ─────────────────────────────────────────────

required_pkgs <- c(
  "data.table",    # fast data manipulation
  "fixest",        # fixed effects estimation
  "did",           # Callaway-Sant'Anna staggered DiD
  "ggplot2",       # plotting (for diagnostics only)
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  "jsonlite",      # diagnostics output
  "HonestDiD",     # sensitivity analysis for pre-trends
  "sandwich",      # robust standard errors
  "lmtest"         # hypothesis tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
