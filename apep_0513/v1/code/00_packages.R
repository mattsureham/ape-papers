## 00_packages.R — Load all required packages
## apep_0513: Welsh 20mph Speed Limit

required <- c(
  "stats19",        # STATS19 road casualty data
  "data.table",     # Fast data manipulation
  "fixest",         # Two-way fixed effects, cluster-robust SEs
  "ggplot2",        # Figures
  "scales",         # Axis formatting
  "dplyr",          # Data wrangling
  "tidyr",          # Reshape
  "readr",          # CSV reading
  "lubridate",      # Date handling
  "stringr",        # String operations
  "fwildclusterboot", # Wild cluster bootstrap
  "modelsummary",   # Regression tables
  "kableExtra",     # Table formatting
  "patchwork",      # Combine ggplot panels
  "arrow"           # Parquet/large CSV handling
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## Theme for figures
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    axis.title = element_text(size = 11)
  ))

cat("All packages loaded successfully.\n")
