## 00_packages.R — Load and install required packages
## APEP paper apep_0737: Dodd-Frank $10B Bunching

required_packages <- c(
  "tidyverse",     # data manipulation + ggplot2

"data.table",    # fast data wrangling
  "fixest",        # fixed effects regression
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "xtable",        # LaTeX table output
  "boot",          # bootstrap inference
  "scales",        # formatting
  "knitr"          # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
