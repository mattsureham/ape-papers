## 00_packages.R — Install and load required packages
## APEP paper apep_0814: El Salvador gang removal and nighttime economic activity

pkgs <- c(
  "sf", "terra", "geodata", "exactextractr",   # spatial
  "httr2", "jsonlite", "curl",                  # API
  "data.table", "dplyr", "tidyr",               # data wrangling
  "fixest",                                      # DiD estimation
  "modelsummary", "kableExtra",                  # tables
  "ggplot2",                                     # plotting (for diagnostics only)
  "blackmarbler"                                 # VIIRS nightlights
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    message("Installing: ", p)
    install.packages(p, repos = "https://cran.r-project.org", quiet = TRUE)
  }
}

invisible(lapply(pkgs, library, character.only = TRUE))

message("All packages loaded successfully.")
