## 00_packages.R — Load libraries and set themes
## TLV Vacancy Tax Expansion — apep_0523

reqpkgs <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "ggplot2", "scales", "patchwork",
  "xtable", "kableExtra",
  "HonestDiD",
  "arrow"
)

for (pkg in reqpkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
