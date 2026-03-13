## 00_packages.R — Load and install required packages
## apep_0610: The Marginal Birth

pkgs <- c(
  "data.table", "tidyverse", "fixest", "did", "HonestDiD",
  "httr", "jsonlite", "readr", "readxl",
  "modelsummary", "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
