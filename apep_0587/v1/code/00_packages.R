## =============================================================================
## 00_packages.R — Load libraries and set global options
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================

# CRAN packages
pkgs <- c(
  "data.table", "readODS", "httr2", "jsonlite",  # data
  "ggplot2", "scales", "patchwork",                # figures
  "boot", "splines",                                # analysis
  "xtable", "knitr"                                 # tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

# ggplot2 theme
theme_set(
  theme_minimal(base_size = 11, base_family = "serif") +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      legend.position = "bottom"
    )
)

cat("Packages loaded successfully.\n")
