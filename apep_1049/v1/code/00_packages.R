# 00_packages.R — Package installation and loading for apep_1049
# EU Single-Use Plastics Directive: Substitution Illusion

required_packages <- c(
  "data.table", "dplyr", "tidyr", "ggplot2",
  "fixest", "did",             # DiD estimation
  "eurostat",                  # Eurostat API
  "eurlex",                    # CELLAR SPARQL for transposition dates
  "httr2", "jsonlite",        # API calls
  "xtable", "knitr",          # Table generation
  "HonestDiD"                 # Sensitivity analysis for parallel trends
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(fixest)
  library(did)
  library(eurostat)
  library(eurlex)
  library(httr2)
  library(jsonlite)
  library(HonestDiD)
})

message("All packages loaded successfully.")
