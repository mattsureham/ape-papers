## 00_packages.R — Load and install required packages
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

required <- c(
  "data.table", "fixest", "ggplot2", "jsonlite", "lubridate",
  "stringr", "readr", "httr", "sandwich", "lmtest", "modelsummary",
  "kableExtra", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
