## 00_packages.R — apep_0931: IAP and Economic Development
## Install and load required packages

pkgs <- c("data.table", "fixest", "ggplot2", "dplyr", "tidyr", "jsonlite",
          "kableExtra", "xtable", "did", "HonestDiD", "sandwich", "lmtest")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
