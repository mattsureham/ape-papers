## 00_packages.R — Install and load required packages
## APEP-0683: Council Tax Empty Homes Premium and Vacancy

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects, Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "HonestDiD",    # Rambachan-Roth sensitivity
  "bacondecomp",  # Goodman-Bacon decomposition
  "readODS",      # read .ods (Table 615)
  "readxl",       # read .xlsx (CTB data)
  "httr2",        # HTTP requests
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "data.table"    # memory-efficient operations
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
