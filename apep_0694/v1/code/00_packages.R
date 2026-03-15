## 00_packages.R — Install and load required packages
## apep_0694: HomeBuilder Net Additionality

pkgs <- c(
  "tidyverse", "fixest", "data.table",
  "modelsummary", "kableExtra", "jsonlite",
  "httr", "rsdmx"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
