## 00_packages.R — Install and load required packages
## apep_0913: Wilderness spatial RDD

pkgs <- c(
  "tidyverse", "sf", "terra", "rdrobust", "rddensity",
  "fixest", "sandwich", "lmtest", "jsonlite",
  "xtable", "kableExtra", "httr", "curl"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
