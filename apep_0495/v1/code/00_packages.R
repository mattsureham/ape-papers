## 00_packages.R — Install and load required packages
## apep_0495: Private School VAT and State School Housing Premium

required_packages <- c(
  "data.table", "arrow", "duckdb",        # Data handling (large files)
  "fixest", "did", "HonestDiD",           # DiD estimation
  "ggplot2", "ggthemes", "scales",        # Visualization
  "sf", "PostcodesioR",                   # Geography/geocoding
  "httr2", "curl", "jsonlite",            # API access
  "modelsummary", "kableExtra",           # Tables
  "sandwich", "lmtest",                   # Robust inference
  "stargazer",                            # LaTeX table output
  "geosphere"                             # Distance calculations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

## ggplot2 theme for publication
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
