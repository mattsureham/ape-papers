# 00_packages.R — Load required packages for apep_0785
# Quiet zone designations and property values

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects, Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "data.table",   # efficient data wrangling
  "jsonlite",     # JSON I/O
  "httr",         # API calls
  "lubridate"     # date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
