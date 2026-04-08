# 00_packages.R — Pipeline Scars (apep_1404)
# Required packages for RDD analysis of PHMSA significant incident threshold

required_packages <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr",
  "ggplot2", "rdrobust", "rddensity", "fixest",
  "xtable", "jsonlite", "scales", "purrr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Set theme
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    axis.title = element_text(size = 11)
  ))

cat("All packages loaded.\n")
