## 00_packages.R — Load and install required packages
## APEP-0861: Austerity Triage and Domestic Abuse Justice

pkgs <- c(
  "tidyverse", "fixest", "data.table", "httr2", "jsonlite",
  "readxl", "janitor", "haven", "modelsummary", "kableExtra",
  "sandwich", "lmtest", "xtable", "readODS"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
