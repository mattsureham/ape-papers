# 00_packages.R — Load all required packages
# APEP-0569: Egypt Devaluation Import Compression

required <- c(
  "httr", "jsonlite", "data.table", "fixest", "ggplot2",
  "modelsummary", "scales", "kableExtra", "readxl", "writexl"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# ggplot theme for publication
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    axis.title = element_text(size = 10),
    strip.text = element_text(face = "bold")
  ))

cat("All packages loaded.\n")
