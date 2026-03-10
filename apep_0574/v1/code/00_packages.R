## 00_packages.R — Install and load required packages
## APEP-0574: Gas Shock Import Substitution

required_packages <- c(
  "data.table", "dplyr", "tidyr", "stringr", "lubridate",
  "fixest", "ggplot2", "scales", "patchwork",
  "eurostat", "httr", "jsonlite",
  "xtable", "kableExtra",
  "HonestDiD"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ggplot theme
theme_set(
 theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 12),
      strip.text = element_text(face = "bold")
    )
)

cat("All packages loaded successfully.\n")
