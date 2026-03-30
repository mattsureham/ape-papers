## 00_packages.R — Install and load required packages
## apep_1156: Mexico AVGM and Domestic Violence Reporting

pkgs <- c(
  "tidyverse", "data.table", "fixest", "did",
  "jsonlite", "xtable", "broom", "fwildclusterboot"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
