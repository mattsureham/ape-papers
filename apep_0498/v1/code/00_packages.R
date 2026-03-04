## =============================================================================
## 00_packages.R — Load required libraries and set global options
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

## CRAN packages
pkgs <- c(
  "data.table", "httr", "jsonlite", "readxl",   # Data I/O
  "fixest", "did", "HonestDiD",                  # Econometrics
  "ggplot2", "ggthemes", "patchwork", "scales",   # Visualization
  "modelsummary", "kableExtra",                   # Tables
  "fwildclusterboot",                             # Wild cluster bootstrap
  "curl"                                          # Downloads
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

## Global ggplot theme — clean, journal-ready
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 12),
      plot.caption = element_text(size = 8, hjust = 0, color = "grey40")
    )
)

## Paths (relative to code/ directory)
DATA_DIR    <- "../data"
FIG_DIR     <- "../figures"
TABLE_DIR   <- "../tables"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("✓ Packages loaded, theme set, paths configured.\n")
