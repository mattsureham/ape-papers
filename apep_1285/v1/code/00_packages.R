## 00_packages.R — Load required packages
## APEP-1285: AEOI Shock and Swiss Real Estate

required <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # TWFE with cluster-robust SE
  "data.table",  # fast data manipulation
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "xtable",      # LaTeX table output
  "fwildclusterboot",  # wild cluster bootstrap (few clusters)
  "sandwich",    # robust SE
  "lmtest"       # coeftest
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
