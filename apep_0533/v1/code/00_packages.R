## 00_packages.R — Load libraries and set global options
## apep_0533: Salary History Bans and the Gender Earnings Gap

# Core packages
library(data.table)
library(fixest)
library(did)         # Callaway-Sant'Anna
library(ggplot2)
library(httr)
library(jsonlite)

# Utility
library(knitr)
library(kableExtra)
library(scales)
library(xtable)

# Set ggplot theme
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 11),
    legend.position = "bottom"
  ))

# Output directories
fig_dir <- "../figures/"
tab_dir <- "../tables/"
data_dir <- "../data/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded successfully.\n")
