## 00_packages.R — Load libraries and set themes
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

# Core packages
library(data.table)
library(fixest)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(httr)
library(jsonlite)
library(purrr)

# DiD packages
library(did)          # Callaway & Sant'Anna (2021)
library(HonestDiD)    # Rambachan & Roth (2023)

# Extras
library(xtable)       # LaTeX table output
library(scales)       # Axis formatting

# ggplot theme for publication
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 10),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  ))

# Color palette
apep_colors <- c(
  "treated" = "#E41A1C",
  "control" = "#377EB8",
  "ci" = "grey80",
  "highlight" = "#FF7F00"
)

cat("Packages loaded successfully.\n")
