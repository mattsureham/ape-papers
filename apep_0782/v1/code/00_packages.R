# 00_packages.R — Install and load required packages
# apep_0782: MSHA 2007 Penalty Reform and Mine Injury Deterrence

pkgs <- c(
  "data.table",   # Fast data manipulation
  "fixest",       # Fast fixed effects estimation
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "here"          # Reproducible file paths
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
