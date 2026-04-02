## 00_packages.R — Load required packages
## apep_0959 V2: The Detection Dividend — Endogenous Regulatory Metrics

required_packages <- c(
  "data.table", "fixest", "did", "ggplot2",
  "modelsummary", "kableExtra", "jsonlite",
  "lubridate", "stringr", "HonestDiD",
  "sandwich", "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Optional packages (try but don't fail)
optional_pkgs <- c("bacondecomp")
for (pkg in optional_pkgs) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    library(pkg, character.only = TRUE)
  }
}

cat("All packages loaded.\n")
