## ============================================================================
## 00_packages.R — Load libraries and set global options
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================

# Core data manipulation
library(data.table)
library(readxl)
library(httr)
library(jsonlite)

# Econometrics
library(fixest)
library(sandwich)
library(lmtest)

# Visualization
library(ggplot2)
library(patchwork)
library(scales)

# Theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 10, color = "gray40"),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
)

# Palette for eat-in vs takeout
eat_in_color   <- "#E63946"  # red
takeout_color  <- "#457B9D"  # blue
alcohol_color  <- "#2A9D8F"  # teal (placebo)
neutral_color  <- "#6C757D"  # gray

cat("Packages loaded successfully.\n")
