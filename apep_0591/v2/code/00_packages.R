# =============================================================================
# 00_packages.R — Load and install required packages
# APEP-0591 v2: The Erasmus Drain (NUTS3 Long-Difference Revision)
# =============================================================================

required_pkgs <- c(
  "data.table", "arrow", "eurostat", "fixest", "ggplot2",
  "scales", "knitr", "kableExtra", "sf", "rnaturalearth",
  "rnaturalearthdata", "jsonlite", "httr", "sandwich"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Set global options
options(scipen = 999)
setDTthreads(parallel::detectCores())

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
