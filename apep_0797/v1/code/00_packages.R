# 00_packages.R — Load required packages
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

required_packages <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "lubridate", "jsonlite", "modelsummary", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

message("All packages loaded successfully.")
