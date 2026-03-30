# 00_packages.R — Install and load required packages
# apep_1131: The Hollow Safety Net

pkgs <- c("tidyverse", "fixest", "httr", "rvest", "jsonlite",
          "data.table", "sandwich", "lmtest", "fwildclusterboot", "xtable")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
