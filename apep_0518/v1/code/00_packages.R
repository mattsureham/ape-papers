## =============================================================================
## 00_packages.R — Load libraries and set global options
## =============================================================================

# CRAN packages
pkgs <- c(
  "data.table", "sf", "dplyr", "tidyr", "ggplot2", "fixest",
  "arrow", "httr", "jsonlite", "purrr", "stringr",
  "knitr", "kableExtra", "modelsummary", "did", "HonestDiD",
  "sandwich", "lmtest", "MASS"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

# Global options
options(scipen = 999)
setDTthreads(parallel::detectCores() - 1)

# ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
apep_cols <- c(
  lost   = "#E63946",  # Red - lost status
  kept   = "#457B9D",  # Blue - kept status
  gained = "#2A9D8F",  # Teal - gained status
  never  = "#A8DADC"   # Light - never treated
)

cat("Packages loaded successfully.\n")
