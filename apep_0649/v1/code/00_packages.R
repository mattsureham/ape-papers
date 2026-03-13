## 00_packages.R — Install and load required packages
## apep_0649: Clean Air Zone property values

pkgs <- c(
  "data.table", "sf", "httr2", "jsonlite",    # data + spatial + API
  "fixest", "rdrobust", "modelsummary",        # estimation + tables
  "sandwich", "lmtest",                         # robust inference
  "kableExtra"                                  # LaTeX table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
