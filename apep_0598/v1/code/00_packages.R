# 00_packages.R — Load libraries and set themes
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

required_packages <- c(
  "tidyverse", "data.table", "eurostat", "Synth", "augsynth",
  "fixest", "modelsummary", "kableExtra", "ggplot2", "scales",
  "lubridate", "httr", "jsonlite", "patchwork"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# ggplot2 theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 11),
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
apep_colors <- c(
  "Greece" = "#1b4f72",
  "Synthetic" = "#e74c3c",
  "Donor" = "grey70",
  "Fuel (G473)" = "#e74c3c",
  "Food (G472)" = "#f39c12",
  "Non-specialized (G471)" = "#27ae60"
)

cat("Packages loaded successfully.\n")
