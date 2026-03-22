## 00_packages.R — Install and load required packages
## APEP-0740: QPV Designation Paradox

pkgs <- c(
  "data.table", "sf", "rdrobust", "rddensity", "fixest",
  "xtable", "jsonlite", "curl"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
