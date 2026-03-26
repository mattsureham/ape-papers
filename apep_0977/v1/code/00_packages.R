## 00_packages.R — Install and load required packages
## apep_0977: Korea-Japan boycott trade hysteresis

required_pkgs <- c(
  "tidyverse", "fixest", "httr2", "jsonlite", "data.table",
  "modelsummary", "kableExtra", "sandwich"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
