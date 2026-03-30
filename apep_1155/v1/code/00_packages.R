## 00_packages.R — Install and load required packages
## apep_1155: El Salvador State of Exception

required_pkgs <- c(
  "data.table", "fixest", "dplyr", "tidyr", "sf", "terra",
  "geodata", "httr", "jsonlite", "readxl", "xtable", "stringr"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# BlackMarbleR from World Bank (GitHub)
if (!requireNamespace("blackmarbler", quietly = TRUE)) {
  if (!requireNamespace("devtools", quietly = TRUE))
    install.packages("devtools", repos = "https://cloud.r-project.org")
  devtools::install_github("worldbank/blackmarbler")
}
library(blackmarbler)

# fwildclusterboot for wild cluster bootstrap
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

cat("All packages loaded successfully.\n")
