## 00_packages.R — Load required packages for CROWN Act analysis
## apep_1066 v1

pkgs <- c(
  "tidyverse",
  "fixest",
  "did",
  "httr",
  "jsonlite",
  "modelsummary",
  "kableExtra",
  "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
