# 00_packages.R — Load and install required packages
required <- c("tidyverse", "fixest", "data.table", "jsonlite",
              "sandwich", "lmtest", "fwildclusterboot")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
