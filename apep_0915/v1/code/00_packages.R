## 00_packages.R — Load and install required packages
## apep_0915: HAP Emission Bunching at CAA Thresholds

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "data.table",   # memory-efficient large data ops
  "fixest",       # fast fixed effects estimation
  "boot",         # bootstrap inference
  "jsonlite",     # diagnostics.json output
  "xtable",       # LaTeX table generation
  "knitr",        # additional table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
