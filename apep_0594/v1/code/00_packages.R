## 00_packages.R — Load libraries and set global options
## apep_0594: Spain's 2022 Temporary Contract Ban

# Core
library(tidyverse)
library(data.table)
library(jsonlite)
library(httr)

# Econometrics
library(fixest)
library(sandwich)
library(lmtest)
library(fwildclusterboot)  # Wild cluster bootstrap for few clusters

# Tables and figures
library(knitr)
library(kableExtra)
library(ggplot2)
library(scales)
library(patchwork)

# Set ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Paths
base_dir <- file.path(dirname(dirname(getwd())), "output", "apep_0594", "v1")
if (!dir.exists(base_dir)) {
  base_dir <- "."
}
data_dir <- file.path(base_dir, "data")
fig_dir  <- file.path(base_dir, "figures")
tab_dir  <- file.path(base_dir, "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base dir:", base_dir, "\n")
