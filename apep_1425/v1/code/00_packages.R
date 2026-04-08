## 00_packages.R — apep_1425
## Leniency Compression in Brazilian Labor Courts

pkgs <- c(
  "data.table", "fixest", "jsonlite", "httr2",
  "ggplot2", "kableExtra", "modelsummary", "sandwich",
  "stargazer", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
