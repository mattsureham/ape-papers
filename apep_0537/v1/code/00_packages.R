## 00_packages.R — Load libraries and set themes for apep_0537
## GenAI as Seniority-Biased Technological Change

# Core
library(tidyverse)
library(data.table)
library(fixest)

# Data access
library(httr)
library(jsonlite)
library(readxl)

# Tables / output
library(modelsummary)
library(kableExtra)

# Set ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
apep_colors <- c(
  "Entry-Level" = "#E63946",
  "Mid-Level" = "#457B9D",
  "Senior" = "#2A9D8F",
  "High GenAI" = "#E63946",
  "Low GenAI" = "#457B9D"
)

cat("Packages loaded successfully.\n")
