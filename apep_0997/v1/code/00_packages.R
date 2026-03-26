## 00_packages.R — Install and load required packages
## apep_0997: Romania Construction Tax Holiday

pkgs <- c(
  "tidyverse", "fixest", "data.table", "eurostat",
  "jsonlite", "httr", "modelsummary", "kableExtra",
  "sandwich", "fwildclusterboot", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
