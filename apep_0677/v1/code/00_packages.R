## 00_packages.R — EUDR Trade Diversion DDD
## Install and load required packages

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "httr2", "jsonlite",
  "sandwich", "lmtest", "modelsummary", "kableExtra", "xtable"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
