## 00_packages.R — Load libraries and set themes
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

# Core
library(tidyverse)
library(data.table)
library(fixest)

# Data
library(httr)
library(jsonlite)
library(fredr)

# Tables and figures
library(knitr)
library(kableExtra)
library(ggthemes)
library(scales)
library(patchwork)

# Inference
library(sandwich)
library(lmtest)

# Load .env file
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    if (grepl("^[A-Z_]+=", line) && !grepl("^#", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      key <- parts[1]
      val <- paste(parts[-1], collapse = "=")
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

# Set FRED API key
fredr_set_key(Sys.getenv("FRED_API_KEY"))

# APEP figure theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.line = element_line(color = "black", linewidth = 0.3),
      axis.ticks = element_line(color = "black", linewidth = 0.3),
      plot.title = element_text(face = "bold", size = rel(1.1)),
      plot.subtitle = element_text(size = rel(0.9), color = "grey30"),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      plot.margin = margin(10, 15, 10, 10)
    )
}

theme_set(theme_apep())

# Color palette
apep_colors <- c(
  "East Coast"  = "#E64B35",
  "Gulf Coast"  = "#F39B7F",
  "West Coast"  = "#4DBBD5",
  "Other"       = "#91D1C2",
  "Treatment"   = "#E64B35",
  "Control"     = "#4DBBD5"
)

cat("Packages loaded successfully.\n")
