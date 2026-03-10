#' 00_packages.R — Package loading and theme setup for apep_0577
#' REACH 2018 Deadline and Chemical Industry Restructuring

# Core packages
library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(fixest)
library(eurostat)

# For wild cluster bootstrap and RI
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

# For tables
if (!requireNamespace("modelsummary", quietly = TRUE)) {
  install.packages("modelsummary", repos = "https://cloud.r-project.org")
}
library(modelsummary)

# APEP ggplot theme
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40"),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.title = element_text(size = base_size),
      axis.text = element_text(size = base_size - 1),
      legend.position = "bottom",
      legend.title = element_text(size = base_size - 1),
      plot.caption = element_text(hjust = 0, color = "grey50", size = base_size - 2),
      strip.text = element_text(face = "bold")
    )
}

theme_set(theme_apep())

# Color palette
apep_colors <- c(
  "treated" = "#E63946",
  "control" = "#457B9D",
  "highlight" = "#F4A261",
  "neutral" = "#2A9D8F",
  "dark" = "#264653"
)

cat("Packages loaded. Theme set.\n")
