# 00_packages.R — Load required packages
# apep_1399: The Bedrock Dose

required_packages <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "jsonlite", "httr", "sf", "viridis", "patchwork",
  "kableExtra", "modelsummary", "scales", "did"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "gray40"),
    strip.text = element_text(face = "bold")
  ))

cat("Packages loaded successfully.\n")
