## 00_packages.R — Load required packages for Norway wealth tax analysis
## apep_0658

required_packages <- c(
  "httr", "jsonlite",  # SSB API
  "dplyr", "tidyr", "stringr", "readr", "purrr",  # data wrangling
  "fixest",  # fast FE estimation
  "did",  # Callaway-Sant'Anna
  "modelsummary",  # table formatting
  "kableExtra",  # LaTeX table output
  "sandwich", "lmtest"  # robust inference
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
