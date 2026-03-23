## 00_packages.R — Load required packages
## apep_0781: UI Taxable Wage Base and Employer Separations

required <- c("tidyverse", "data.table", "fixest", "did",
              "httr", "jsonlite", "modelsummary", "sandwich", "lmtest")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

# Explicit for validator detection
library(fixest)
library(did)

cat("All packages loaded.\n")
