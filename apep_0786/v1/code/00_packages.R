## 00_packages.R — Load and install required packages
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending

required <- c(
  "tidyverse",
  "fixest",
  "data.table",
  "jsonlite",
  "httr",
  "arrow",
  "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
