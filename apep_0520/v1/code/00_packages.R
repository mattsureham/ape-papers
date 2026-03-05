## ============================================================================
## 00_packages.R — Load libraries and set global options
## Paper: Does Coverage Create Capacity? 1115 SUD Waivers and BH Provider Supply
## ============================================================================

options(scipen = 999, digits = 4)

## ---- Required packages ----
pkgs <- c(
  "data.table", "arrow", "ggplot2", "fixest", "did",
  "dplyr", "tidyr", "stringr", "lubridate", "purrr",
  "sandwich", "lmtest", "xtable", "kableExtra",
  "scales", "RColorBrewer", "viridis",
  "HonestDiD", "fwildclusterboot"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

## ---- ggplot2 theme ----
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  ))

cat("Packages loaded.\n")
