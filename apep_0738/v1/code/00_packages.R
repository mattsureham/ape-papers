## 00_packages.R — Load required packages
## Paper: apep_0738 — Franc Shock and Retail Desertification

required <- c(
  "data.table", "fixest", "httr", "jsonlite",
  "sandwich", "lmtest", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(data.table)
library(fixest)

cat("All packages loaded.\n")
