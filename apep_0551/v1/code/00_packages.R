## ============================================================
## 00_packages.R — Install and load required packages
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "httr", "jsonlite",
  "readr", "stringr", "dplyr", "tidyr", "purrr",
  "modelsummary", "kableExtra", "sandwich", "lmtest",
  "did", "broom", "scales", "lubridate"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 13),
      axis.title = element_text(size = 11),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
