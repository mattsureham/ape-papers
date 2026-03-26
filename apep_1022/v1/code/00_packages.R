## 00_packages.R — Load required packages for apep_1022
## Affirmative action bans and minority enrollment cascades

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE comparison
  "did",          # Callaway-Sant'Anna
  "data.table",   # fast data operations
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "kableExtra",   # table formatting
  "xtable"        # LaTeX table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
