## 00_packages.R — Load and install required packages
## apep_1408: PNIS coca substitution in Colombia

required <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "httr", "ggplot2", "scales", "kableExtra", "modelsummary",
  "sandwich", "lmtest", "fwildclusterboot", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
