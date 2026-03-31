## 00_packages.R — Install and load required packages
## apep_1208: Ghana DDEP and Private Sector Credit

required <- c(
  "tidyverse", "httr", "jsonlite",  # Data wrangling + API
  "Synth",                           # Synthetic control method
  "fixest",                          # DiD regressions
  "xtable",                          # LaTeX table output
  "boot"                             # Bootstrap inference
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
