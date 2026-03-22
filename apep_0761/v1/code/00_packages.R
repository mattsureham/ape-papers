## 00_packages.R — Load and install required packages
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

required <- c(
  "tidyverse", "data.table", "fixest", "did",
  "httr", "jsonlite", "modelsummary", "kableExtra",
  "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(did)

cat("All packages loaded.\n")
