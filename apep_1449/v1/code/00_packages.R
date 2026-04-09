## 00_packages.R — Install and load required packages
pkgs <- c("data.table", "fixest", "suncalc", "ggplot2", "kableExtra",
          "jsonlite", "lubridate", "sandwich", "lmtest")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
