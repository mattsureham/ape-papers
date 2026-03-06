## 00_packages.R — Load libraries and set options
## APEP Paper apep_0539: Less Cash, Less Crime?

# Core
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)
library(did)          # Callaway-Sant'Anna
library(HonestDiD)    # Rambachan-Roth sensitivity
library(bacondecomp)  # Bacon decomposition
# fwildclusterboot not available for this R version; use boottest via fixest

# Data
library(readxl)
library(httr)
library(jsonlite)

# Tables + Figures
library(modelsummary)
library(kableExtra)
library(ggplot2)
library(patchwork)
library(scales)
library(RColorBrewer)

# Set options
options(scipen = 999, digits = 4)
setFixest_nthreads(parallel::detectCores())

# APEP ggplot theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40", size = base_size),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(face = "bold"),
      plot.caption = element_text(color = "grey50", hjust = 0)
    )
}
theme_set(theme_apep())

cat("Packages loaded successfully.\n")
