## 00_packages.R — Load and verify required packages

required_packages <- c(
  "tidyverse",
  "fixest",      # TWFE with clustered SEs
  "did",         # Callaway-Sant'Anna DiD
  "rdrobust",    # RD estimation
  "rddensity",   # McCrary density test
  "sandwich",    # Robust SEs
  "lmtest",      # coeftest
  "broom",       # tidy model output
  "jsonlite",    # diagnostics.json
  "knitr",       # table formatting
  "xtable",      # LaTeX tables
  "scales",      # number formatting
  "haven"        # data import
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
