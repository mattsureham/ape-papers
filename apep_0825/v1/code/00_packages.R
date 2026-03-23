## 00_packages.R — Load required libraries
## apep_0825: Networked Backlash in Sweden

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readr",        # CSV reading
  "data.table",   # fast data operations
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "fwildclusterboot", # wild cluster bootstrap (21 clusters)
  "xtable",       # LaTeX tables
  "modelsummary"  # regression tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
