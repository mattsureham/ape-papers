## 00_packages.R — Install and load required packages
pkgs <- c("tidyverse", "fixest", "eurostat", "data.table", "jsonlite",
          "sandwich", "lmtest", "modelsummary", "kableExtra", "xtable")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
