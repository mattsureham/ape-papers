##============================================================
## 00_packages.R — Load required packages
## APEP-0543: Rent Control and Property Values in France
##============================================================

required_packages <- c(
  "tidyverse",    # Data manipulation + ggplot2

"data.table",   # Memory-efficient data operations
  "fixest",       # Fixed effects estimation (feols)
  "did",          # Callaway-Sant'Anna staggered DiD
  "arrow",        # Parquet / memory-efficient file I/O
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "HonestDiD",    # Rambachan-Roth sensitivity
  ## "fwildclusterboot", # Not available for this R version
  "scales",       # Axis formatting
  "sf",           # Spatial data
  "patchwork"     # Combine ggplot panels
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## APEP figure theme
theme_apep <- theme_classic(base_size = 12) +
  theme(
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    plot.caption = element_text(size = 8, color = "gray50")
  )
theme_set(theme_apep)

## Color palette
apep_colors <- c(
  "treated" = "#E63946",
  "control" = "#457B9D",
  "investment" = "#E76F51",
  "owneroccupied" = "#2A9D8F",
  "placebo" = "#6C757D"
)

cat("All packages loaded successfully.\n")
