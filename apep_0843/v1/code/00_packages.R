## 00_packages.R — Load required libraries for apep_0843
## RON Laws and New Business Formation

required_packages <- c(
  "tidyverse",   # data manipulation + ggplot2
  "fixest",      # TWFE baseline
  "did",         # Callaway-Sant'Anna
  "fredr",       # FRED API
  "jsonlite",    # diagnostics.json
  "kableExtra",  # table formatting
  "HonestDiD",   # Rambachan-Roth sensitivity
  "sandwich",    # robust SEs
  "lmtest"       # coeftest
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
