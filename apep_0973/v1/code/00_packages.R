## 00_packages.R — Install and load required packages
## APEP-0973: Plastic Bag Charges and Beach Litter

required <- c(
  "tidyverse",    # data wrangling + ggplot2
  "data.table",   # fast I/O
  "fixest",       # TWFE and Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "modelsummary", # regression tables
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
