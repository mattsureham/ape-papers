## 00_packages.R — Hospital Bed Bunching Atlas

pkgs <- c("tidyverse", "data.table", "fixest", "jsonlite", "xtable",
          "httr", "scales", "broom")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE))
    install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
