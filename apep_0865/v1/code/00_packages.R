## 00_packages.R — Install and load required packages
## apep_0865: Last Call for Competition

pkgs <- c(
  "tidyverse", "fixest", "rdrobust", "rddensity",
  "httr", "jsonlite", "data.table", "sandwich",
  "lmtest", "modelsummary", "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
