## 00_packages.R — Load required libraries
## apep_1177 v2: The Conviction Lottery

suppressPackageStartupMessages({
  # Core
  library(data.table)
  library(arrow)
  library(jsonlite)

  # IV / Econometrics
  library(fixest)      # feols, feiv — fast FE-IV with clustering
  library(ivreg)       # ivreg — classical 2SLS + diagnostics

  # Diagnostics
  library(sandwich)    # vcovCL — cluster-robust SEs
  library(lmtest)      # coeftest — hypothesis tests

  # Tables
  library(modelsummary) # msummary — regression tables
  library(kableExtra)   # kbl — LaTeX tables

  # Figures (V2 has figures)
  library(ggplot2)
  library(scales)

  # Utilities
  library(stringr)
  library(lubridate)
})

# ggplot theme for publication
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "bottom"
  )
theme_set(theme_apep)

cat("All packages loaded for apep_1177 v2.\n")
