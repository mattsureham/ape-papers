## 00_packages.R — Install and load required packages
## APEP paper apep_0918: ULEZ expansion and NO2

required <- c(
  "data.table", "jsonlite", "httr", "curl",
  "fixest", "did", "HonestDiD",
  "ggplot2", "modelsummary", "kableExtra",
  "sf", "geosphere",
  "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
