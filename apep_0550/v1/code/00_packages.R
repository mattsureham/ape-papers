## 00_packages.R — Load and install required packages
## apep_0550: India Farm Laws Symmetric Natural Experiment

required <- c(
  "data.table", "fixest", "ggplot2", "jsonlite", "httr",
  "did", "HonestDiD", "modelsummary", "kableExtra",
  "purrr", "stringr", "lubridate", "scales",
  "fwildclusterboot"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## Global ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "grey40"),
      legend.position = "bottom"
    )
)

cat("All packages loaded.\n")
