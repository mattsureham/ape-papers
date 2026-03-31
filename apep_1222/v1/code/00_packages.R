## 00_packages.R — Install/load required packages
## apep_1222: When the Mine Money Stops

pkgs <- c("tidyverse", "fixest", "data.table", "pdftools", "jsonlite",
          "kableExtra", "xtable", "stringi", "stringdist")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
