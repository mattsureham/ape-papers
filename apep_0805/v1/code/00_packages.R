## 00_packages.R — Install and load required packages
## apep_0805: Prescribed fire liability reform and wildfire severity

pkgs <- c(
  "tidyverse", "data.table", "fixest", "did",
  "DBI", "RSQLite", "httr", "jsonlite",
  "erer",        # daLaw dataset: state prescribed fire liability classification
  "modelsummary" # regression tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
