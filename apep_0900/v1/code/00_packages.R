# 00_packages.R — Load and install required packages
# apep_0900: CBAM product-scope loophole

pkgs <- c(
  "data.table", "fixest", "ggplot2", "httr2", "jsonlite",
  "modelsummary", "kableExtra", "sandwich", "lmtest",
  "eurostat", "countrycode", "scales", "stringr"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
