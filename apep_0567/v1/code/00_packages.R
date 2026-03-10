# ==============================================================================
# 00_packages.R — Load all required packages
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# ==============================================================================

required_packages <- c(
  "data.table", "fixest", "ggplot2", "did",       # Core econometrics
  "rdrobust", "rddensity",                         # RDD
  "httr", "jsonlite", "readr", "readxl",           # Data I/O
  "sf", "stringr", "zoo",                          # Utilities
  "purrr", "dplyr", "tidyr",                       # Data wrangling
  "xtable", "kableExtra",                          # Tables
  "boot", "fwildclusterboot",                      # Inference
  "HonestDiD"                                      # Sensitivity
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 12),
      axis.title = element_text(size = 10)
    )
)

cat("All packages loaded successfully.\n")
