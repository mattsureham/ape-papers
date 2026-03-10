## ==============================================================
## 00_packages.R — Load and install required packages
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "eurostat",
  "httr", "jsonlite", "stringr", "purrr", "dplyr", "tidyr",
  "lubridate", "scales", "ggthemes", "kableExtra", "modelsummary"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

## ggplot2 theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("All packages loaded.\n")
