## 00_packages.R — Load and install required packages

pkgs <- c(
  "tidyverse", "httr", "jsonlite",    # data wrangling + API
  "fixest",                             # two-way FE
  "augsynth",                           # augmented SCM
  "xtable",                             # LaTeX tables
  "scales"                              # formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
