## 00_packages.R — Install and load required packages
## BRRD Bail-In Risk and Household Deposit Structure
## apep_0575

required_packages <- c(
  "data.table", "dplyr", "tidyr", "ggplot2", "fixest",
  "did", "httr2", "jsonlite", "kableExtra", "xtable",
  "HonestDiD", "sandwich", "lmtest", "fwildclusterboot",
  "purrr", "stringr", "lubridate", "scales", "viridis"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ggplot2 theme for publication
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40")
  ))

cat("All packages loaded successfully.\n")
