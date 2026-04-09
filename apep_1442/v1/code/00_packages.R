# 00_packages.R — Package installation and loading for apep_1442
# Planning Inspector Leniency and Housing Supply in England

required <- c(
  "data.table", "fixest", "rvest", "httr", "pdftools",
  "jsonlite", "stringr", "xtable", "knitr", "sandwich",
  "lmtest", "ivreg", "modelsummary"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
