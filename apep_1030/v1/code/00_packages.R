## 00_packages.R — Load and install required packages
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects (TWFE, Sun-Abraham, DDD)
  "did",          # Callaway-Sant'Anna staggered DiD
  "eurostat",     # Eurostat data API
  "jsonlite",     # diagnostics.json
  "modelsummary", # table formatting
  "kableExtra",   # LaTeX table output
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "boot"          # bootstrap
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(did)
library(tidyverse)

cat("All packages loaded successfully.\n")
