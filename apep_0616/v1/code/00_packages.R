## 00_packages.R — Install and load required packages
## apep_0616: Police Austerity and Criminal Justice Quality

pkgs <- c(
  "tidyverse", "fixest", "data.table", "httr2", "jsonlite",
  "readODS", "readxl", "haven", "janitor", "modelsummary",
  "kableExtra", "xtable", "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded successfully.\n")
