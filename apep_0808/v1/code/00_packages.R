## ── 00_packages.R ─────────────────────────────────────────────────────────────
## Install and load packages for apep_0808
## IRS Automatic Revocation Shock: Mass Organizational Death
## ──────────────────────────────────────────────────────────────────────────────

required_pkgs <- c(
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects estimation
  "ggplot2",      # Diagnostics (not for V1 figures)
  "jsonlite",     # JSON output for diagnostics
  "httr",         # API calls
  "xtable",       # LaTeX table generation
  "sandwich",     # Robust SEs
  "lmtest",       # Hypothesis testing
  "margins"       # Marginal effects for logit
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## Explicit library calls for validator detection
library(data.table)
library(fixest)

cat("All packages loaded successfully.\n")
