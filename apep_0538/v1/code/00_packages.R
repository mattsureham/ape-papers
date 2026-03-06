## 00_packages.R — Load and install required packages
## APEP-0538: ZFE Housing Price Capitalization

required_pkgs <- c(
  "data.table", "sf", "fixest", "ggplot2",
  "httr", "jsonlite", "geojsonsf",
  "modelsummary", "kableExtra",
  "did",        # Callaway & Sant'Anna
  "scales", "viridis"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## ggplot2 theme for publication-quality figures
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 11),
    legend.position = "bottom"
  ))

cat("All packages loaded successfully.\n")
