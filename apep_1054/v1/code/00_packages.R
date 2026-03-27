## 00_packages.R — Install and load required packages
## apep_1054: Mexico DST Abolition and Crime

pkgs <- c(
  "data.table", "fixest", "readxl", "httr", "jsonlite",
  "stringr", "fwildclusterboot", "modelsummary", "kableExtra"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
