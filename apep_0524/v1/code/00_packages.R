## ============================================================
## 00_packages.R — CROWN Act and Black Worker Outcomes
## ============================================================
## Install and load all required packages

required_pkgs <- c(
  "tidyverse",    # Data manipulation + ggplot2

"data.table",   # Fast data operations
  "fixest",       # Fast fixed effects + Sun-Abraham
  "did",          # Callaway-Sant'Anna DiD
  "HonestDiD",    # Rambachan-Roth sensitivity
  "bacondecomp",  # Bacon decomposition
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient testing
  "patchwork",    # Combine ggplot panels
  "ggthemes",     # Additional themes
  "scales",       # Axis formatting
  "httr",         # API calls
  "jsonlite"      # JSON parsing
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

## APEP standard ggplot theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.2)),
      plot.subtitle = element_text(color = "grey40", size = rel(0.9)),
      plot.caption = element_text(color = "grey50", size = rel(0.7)),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

theme_set(theme_apep())

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", packageVersion("fixest") |> as.character(), "\n")
cat("did version:", packageVersion("did") |> as.character(), "\n")
