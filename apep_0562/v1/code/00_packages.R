## ============================================================================
## 00_packages.R — Networked Anxiety (apep_0562)
## Load required packages and set defaults
## ============================================================================

required_pkgs <- c(
  "tidyverse", "data.table", "arrow", "fixest", "glue",
  "ggplot2", "scales", "patchwork", "kableExtra",
  "readxl", "janitor", "sf", "xtable"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

## ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
)

## fixest options
setFixest_dict(c(
  rn_share = "RN Vote Share (%)",
  network_dispersal = "Network Dispersal Exposure",
  post = "Post-2021",
  log_pop = "Log Population",
  unemp_rate = "Unemployment Rate",
  pct_higher_ed = "% Higher Education",
  pct_foreign = "% Foreign-Born",
  log_median_income = "Log Median Income"
))

cat("Packages loaded successfully.\n")
