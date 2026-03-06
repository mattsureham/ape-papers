# ==============================================================================
# 00_packages.R — Load and install required packages
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

required_packages <- c(
  "data.table",
  "fixest",
  "did",
  "ggplot2",
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "lubridate",
  "httr",
  "jsonlite",
  "sf",
  "HonestDiD",
  "kableExtra",
  "xtable",
  "scales",
  "purrr"
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
      axis.title = element_text(size = 10),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
