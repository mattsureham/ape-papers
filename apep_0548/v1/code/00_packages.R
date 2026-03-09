## 00_packages.R — Load libraries and set global options
## APEP-0548: Selective Licensing and Housing Markets in England

options(scipen = 999, timeout = 600)

required_pkgs <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "ggplot2", "ggthemes", "scales", "patchwork",
  "httr2", "jsonlite", "arrow",
  "modelsummary", "kableExtra", "sandwich", "lmtest",
  "HonestDiD"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

## ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey30"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )
theme_set(theme_apep)

cat("Packages loaded successfully.\n")
