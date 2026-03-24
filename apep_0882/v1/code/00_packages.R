## 00_packages.R — Install and load required packages
## apep_0882: Deaths of Despair Through the Resource Cycle

required <- c(
  "tidyverse", "data.table", "fixest", "jsonlite", "httr",
  "sandwich", "lmtest", "broom", "modelsummary",
  "HonestDiD", "fwildclusterboot", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
