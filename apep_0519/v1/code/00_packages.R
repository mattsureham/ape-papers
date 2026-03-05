## 00_packages.R — Install and load required packages
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption

required_pkgs <- c(
  "data.table", "ggplot2", "fixest", "did",
  "httr", "jsonlite", "readr", "readxl",
  "sf", "stringr", "purrr", "scales",
  "HonestDiD", "fwildclusterboot", "bacondecomp",
  "kableExtra", "xtable", "stargazer"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## ggplot theme for publication
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40")
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
