## 00_packages.R — Load and install required packages
## APEP Paper apep_0829: The Goldilocks Examiner

pkgs <- c(
  "tidyverse",
  "fixest",
  "bigrquery",
  "jsonlite",
  "xtable",
  "data.table"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
