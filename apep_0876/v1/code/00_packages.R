## 00_packages.R — Load and install required packages
## Standard econometrics packages (fixest for FE models, data.table for data manipulation)
pkgs <- c("data.table", "fixest", "did", "ggplot2", "jsonlite", "httr", "readr", "stringr")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
