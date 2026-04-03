## 00_packages.R — The Inspector Lottery (apep_1345)
## Required packages for Ofsted inspector-leniency IV analysis

pkgs <- c(
  "data.table", "fixest", "modelsummary", "kableExtra",
  "ggplot2", "httr2", "jsonlite", "readr", "stringr",
  "lubridate", "arrow", "rvest", "xml2"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
