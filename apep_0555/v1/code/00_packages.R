## ============================================================================
## 00_packages.R — Load libraries and set global options
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

## --- Core ---
library(tidyverse)
library(data.table)
library(fixest)

## --- Econometrics ---
library(sandwich)
library(lmtest)
library(fwildclusterboot)

## --- Figures ---
library(ggplot2)
library(patchwork)
library(scales)

## --- Tables ---
library(kableExtra)

## --- Data ---
library(httr)
library(jsonlite)

## --- Global ggplot theme ---
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

## --- Paths ---
root <- here::here()
paper_dir <- file.path(root, "output", "apep_0555", "v1")
code_dir  <- file.path(paper_dir, "code")
data_dir  <- file.path(paper_dir, "data")
fig_dir   <- file.path(paper_dir, "figures")
tab_dir   <- file.path(paper_dir, "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir,  showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Directories set.\n")
