## 00_packages.R — Install and load required packages
## apep_0906: Panama Canal Expansion and Port Labor Markets

pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "httr", "sandwich", "lmtest",
  "modelsummary", "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
