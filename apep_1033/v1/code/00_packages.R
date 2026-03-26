## 00_packages.R — Load and install required packages
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

required_pkgs <- c(
  "tidyverse",   # data wrangling + ggplot

"fixest",      # fixed effects estimation (fepois, feols)
  "did",         # Callaway-Sant'Anna DiD
  "httr",        # HTTP requests for NORS API
  "jsonlite",    # JSON parsing
  "sandwich",    # robust SEs
  "lmtest",      # coeftest
  "MASS",        # negative binomial
  "boot",        # bootstrap
  "xtable",      # LaTeX table output
  "fwildclusterboot",  # wild cluster bootstrap
  "HonestDiD"    # sensitivity analysis for parallel trends
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
