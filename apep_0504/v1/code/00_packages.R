## ============================================================
## 00_packages.R — Package dependencies
## APEP Paper: Does Naming Work?
## ============================================================

# CRAN packages
pkgs <- c(
  "data.table",                        # data handling
  "httr2", "jsonlite", "curl",         # API access
  "fixest", "did", "HonestDiD",        # econometrics
  "ggplot2", "ggthemes", "patchwork",  # figures
  "scales", "modelsummary",            # tables
  "stargazer", "kableExtra",           # LaTeX tables
  "sandwich", "lmtest", "fwildclusterboot", # inference
  "dplyr", "tidyr", "stringr", "lubridate"  # tidyverse
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

# Load core packages
library(data.table)
library(fixest)
library(did)
library(ggplot2)
library(dplyr)
library(lubridate)
library(scales)

# Set ggplot theme
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "bottom"
  ))

cat("All packages loaded successfully.\n")
