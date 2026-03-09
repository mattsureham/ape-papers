# ==============================================================================
# 00_packages.R — Package Loading and Configuration
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

# CRAN packages
pkgs <- c(
  # Data
  "data.table", "jsonlite", "httr", "curl",
  # DiD
  "did", "fixest", "bacondecomp", "HonestDiD",
  # Inference
  "sandwich", "lmtest",
  # Visualization
  "ggplot2", "ggthemes", "patchwork", "scales",
  # Tables
  "modelsummary", "kableExtra",
  # Utilities
  "broom", "dplyr", "tidyr", "stringr", "readr", "purrr"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
