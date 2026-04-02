# 00_packages.R — Load and install required packages
# APEP Paper apep_1292: Sunshine Through the Alps

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2

"fixest",       # TWFE, Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "data.table",   # fast data wrangling
  "jsonlite",     # diagnostics.json output
  "kableExtra",   # table formatting
  "fwildclusterboot", # wild cluster bootstrap
  "xtable"        # LaTeX table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
