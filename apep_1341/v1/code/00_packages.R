# 00_packages.R — Install and load required packages
# apep_1341: Swiss HAT and Drug-Related Crime

required <- c(

"tidyverse",
  "fixest",
  "did",
  # fwildclusterboot not needed for bunching design
  "jsonlite",
  "httr",
  "xtable",
  "kableExtra",
  "modelsummary"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
