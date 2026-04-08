## 00_packages.R — Install and load required packages
## apep_1416: The Legal Status Premium in Local Housing Markets

pkgs <- c(
  "data.table", "fixest", "modelsummary",
  "httr", "jsonlite", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

options(scipen = 999)
setDTthreads(4)
cat("All packages loaded.\n")
