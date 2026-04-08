##############################################################################
# 00_packages.R — Load and install required packages
# apep_1434: When Scandals Go Dark
##############################################################################

required_packages <- c(
  "tidyverse",
  "fixest",
  "httr2",
  "jsonlite",
  "lubridate",
  "sandwich",
  "lmtest",
  "xtable",
  "modelsummary"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
