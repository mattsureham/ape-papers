## 00_packages.R — Install and load required packages
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "httr2", "jsonlite",
  "modelsummary", "kableExtra", "sandwich", "lmtest", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
