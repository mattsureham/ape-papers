## ============================================================================
## 00_packages.R — Install and load packages for apep_0578
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

# CRAN packages
pkgs <- c(
  "eurostat",      # Eurostat API
  "data.table",    # Fast data manipulation
  "fixest",        # TWFE and event studies
  "did",           # Callaway-Sant'Anna estimator
  "ggplot2",       # Figures
  "sf",            # Spatial data
  "dplyr",         # Data wrangling
  "tidyr",         # Reshaping
  "stringr",       # String operations
  "readr",         # CSV I/O
  "purrr",         # Functional programming
  "knitr",         # Tables
  "kableExtra",    # Better tables
  "HonestDiD",     # Rambachan-Roth sensitivity
  "scales",        # Axis formatting
  "viridis",       # Color palettes
  "patchwork"      # Combine plots
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
