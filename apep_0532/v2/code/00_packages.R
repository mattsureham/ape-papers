# ==============================================================================
# 00_packages.R — Package loading and theme setup
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================

# --- Core data wrangling ---
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# --- Econometrics ---
library(fixest)
library(sandwich)
library(lmtest)

# --- Google Trends ---
library(gtrendsR)

# --- Plotting ---
library(ggplot2)
library(ggthemes)
library(patchwork)
library(scales)
library(viridis)

# --- Tables ---
library(kableExtra)
library(modelsummary)

# --- API access ---
library(httr)
library(jsonlite)

# --- ggplot theme ---
theme_apep <- theme_minimal(base_size = 12, base_family = "serif") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey92"),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey30"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("Packages loaded successfully.\n")
