# =============================================================================
# 00_packages.R — Load required packages
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

# CRAN packages
packages <- c(
  "data.table",     # Fast data manipulation
  "ggplot2",        # Visualization
  "fixest",         # Fixed effects estimation
  "sandwich",       # Robust standard errors
  "lmtest",         # Coefficient tests
  "scales",         # Axis formatting
  "lubridate",      # Date handling
  "stringr",        # String manipulation
  "jsonlite",       # JSON I/O
  "rvest",          # Web scraping
  "httr",           # HTTP requests
  "quantmod",       # Yahoo Finance data
  "zoo",            # Time series
  "patchwork",      # Plot composition
  "kableExtra",     # Table formatting
  "readr"           # CSV reading
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# ggplot2 theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "bottom",
    axis.title = element_text(size = 11),
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
