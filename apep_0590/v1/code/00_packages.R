## =============================================================================
## 00_packages.R — apep_0590
## Mexico's Sembrando Vida and the Deforestation Paradox
## =============================================================================

# Core
library(tidyverse)
library(data.table)
library(sf)
library(terra)

# Econometrics
library(fixest)
library(did)          # Callaway-Sant'Anna
library(HonestDiD)    # Rambachan-Roth sensitivity
library(bacondecomp)  # Goodman-Bacon decomposition

# Tables & figures
library(modelsummary)
library(kableExtra)
library(ggplot2)
library(patchwork)
library(scales)

# Data access
library(httr)
library(jsonlite)
library(readxl)

# Set global options
options(
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

# APEP theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40", size = base_size),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      legend.position = "bottom",
      plot.caption = element_text(hjust = 0, color = "grey50", size = base_size - 2),
      strip.text = element_text(face = "bold")
    )
}
theme_set(theme_apep())

cat("Packages loaded successfully.\n")
