## 00_packages.R — Install and load required packages
## apep_0630: Surprise Billing Laws and ED Quality

pkgs <- c(
  "data.table", "fixest", "did", "HonestDiD",
  "modelsummary", "kableExtra", "ggplot2",
  "stringr", "jsonlite", "bacondecomp",
  "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
