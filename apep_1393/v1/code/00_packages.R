## 00_packages.R — Install and load required packages
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

required <- c(
  "tidyverse", "fixest", "data.table", "jsonlite", "httr",
  "modelsummary", "kableExtra", "ggthemes", "scales", "sf",
  "ivreg", "sandwich", "lmtest", "broom", "patchwork"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
