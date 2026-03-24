# 00_packages.R — Install and load required packages
# apep_0847: Stop smoking service austerity and respiratory health

pkgs <- c(
  "dplyr",
  "tidyr",
  "readr",
  "fixest",       # feols for panel FE + IV
  "modelsummary",
  "kableExtra",
  "jsonlite",
  "httr",
  "stringr",
  "readxl",
  "sandwich",
  "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# readODS for .ods files
if (!requireNamespace("readODS", quietly = TRUE)) {
  install.packages("readODS", repos = "https://cloud.r-project.org")
}
library(readODS)

cat("All packages loaded.\n")
