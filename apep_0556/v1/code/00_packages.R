## ============================================================
## 00_packages.R — Load all required packages
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

# CRAN packages
required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Two-way FE, clustered SEs
  "did",           # Callaway-Sant'Anna DiD
  "ggplot2",       # Figures
  "jsonlite",      # DHS API JSON parsing
  "httr",          # HTTP requests
  "modelsummary",  # LaTeX table output
  "kableExtra",    # Table formatting
  "sandwich",      # Robust SEs
  "lmtest",        # Coefficient tests
  "broom",         # Tidy model output
  "HonestDiD",     # Rambachan-Roth sensitivity
  "fwildclusterboot", # Wild cluster bootstrap
  "scales",        # Axis formatting
  "xtable"         # LaTeX tables
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded successfully.\n")

## APEP figure theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      plot.title = element_text(face = "bold", size = base_size + 2, hjust = 0),
      plot.subtitle = element_text(color = "grey40", size = base_size, hjust = 0),
      plot.caption = element_text(color = "grey50", size = base_size - 2, hjust = 1),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
}
theme_set(theme_apep())

cat("APEP theme set.\n")
