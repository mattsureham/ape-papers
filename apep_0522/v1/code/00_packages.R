## ============================================================
## 00_packages.R — Load and install required packages
## apep_0522: Flood Re and English Property Values
## ============================================================

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "lubridate", "httr2", "jsonlite", "sf",
  "scales", "patchwork", "broom", "modelsummary", "kableExtra",
  "HonestDiD"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## ggplot2 theme
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  ))

cat("All packages loaded.\n")
