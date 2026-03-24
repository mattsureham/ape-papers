## 00_packages.R — Install and load required packages
## apep_0872: Hungary bank levy and credit supply

required <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "jsonlite", "httr", "lubridate", "stringr",
  "augsynth",     # Augmented SCM
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SEs
  "lmtest"        # Coefficient tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
