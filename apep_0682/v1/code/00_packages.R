## 00_packages.R — Install and load required packages
## apep_0682: Sewage EDM Information Revelation and House Prices

required_pkgs <- c(
"data.table", "fixest", "did", "ggplot2",
"readxl", "httr2", "jsonlite", "sf",
"RANN", "stringr", "kableExtra", "modelsummary"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
