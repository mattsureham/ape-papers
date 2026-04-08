## 00_packages.R — Load required packages
## apep_1394: Paid Family Leave × Healthcare Workforce Retention

required <- c(
  "tidyverse", "fixest", "data.table", "duckdb", "arrow",
  "lubridate", "modelsummary", "kableExtra", "ggthemes",
  "sandwich", "lmtest", "broom", "scales", "patchwork", "did"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

## APEP ggplot theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
}
theme_set(theme_apep())

cat("Packages loaded.\n")
