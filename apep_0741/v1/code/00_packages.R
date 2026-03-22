## 00_packages.R — Load and install required packages
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

required_pkgs <- c(
  "tidyverse",     # data wrangling + ggplot2

"data.table",    # fast I/O
  "fixest",        # fixed effects regression
  "rdrobust",      # RDD estimation (Cattaneo et al.)
  "sf",            # spatial operations
  "jsonlite",      # diagnostics output
  "xtable",        # LaTeX table generation
  "sandwich",      # robust SEs
  "lmtest",        # coeftest
  "boot"             # bootstrap inference
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
