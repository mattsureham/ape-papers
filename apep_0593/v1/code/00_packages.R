# ============================================================================
# 00_packages.R — Load and install required packages
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

required_packages <- c(
  "data.table", "fixest", "ggplot2", "eurostat", "sf", "giscoR",
  "dplyr", "tidyr", "readr", "stringr", "knitr", "kableExtra",
  "HonestDiD", "did", "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "gray40"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
