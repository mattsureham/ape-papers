## 00_packages.R — Install and load required packages
pkgs <- c("tidyverse", "fixest", "data.table", "jsonlite", "httr",
          "sandwich", "lmtest", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
