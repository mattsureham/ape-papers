## ============================================================
## 00_packages.R — Load libraries and set themes
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

## --- Core packages ---
library(data.table)
library(ggplot2)
library(fixest)
library(httr)
library(jsonlite)
library(readr)

## --- Synthetic control ---
if (!require("Synth")) install.packages("Synth", repos = "https://cloud.r-project.org")
library(Synth)

## --- Robust inference ---
if (!require("SCtools")) install.packages("SCtools", repos = "https://cloud.r-project.org")

## --- Plotting ---
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "grey40"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

## Color palette for Korea vs Synthetic
kor_colors <- c("South Korea" = "#E41A1C", "Synthetic Korea" = "#377EB8",
                "Donor countries" = "grey70")

## Directories
data_dir   <- file.path(getwd(), "..", "data")
fig_dir    <- file.path(getwd(), "..", "figures")
table_dir  <- file.path(getwd(), "..", "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data dir:", data_dir, "\n")
