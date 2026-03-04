## ============================================================
## 00_packages.R — Load libraries and set global options
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

## --- Core packages ---
library(tidyverse)
library(fixest)
library(data.table)
library(lubridate)

## --- Financial data ---
if (!requireNamespace("quantmod", quietly = TRUE)) install.packages("quantmod")
library(quantmod)

## --- Robustness / inference ---
if (!requireNamespace("sandwich", quietly = TRUE)) install.packages("sandwich")
if (!requireNamespace("lmtest", quietly = TRUE)) install.packages("lmtest")
library(sandwich)
library(lmtest)

## --- Tables and figures ---
if (!requireNamespace("xtable", quietly = TRUE)) install.packages("xtable")
if (!requireNamespace("kableExtra", quietly = TRUE)) install.packages("kableExtra")
library(xtable)
library(kableExtra)

## --- APEP theme ---
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "grey30", linewidth = 0.3),
    axis.ticks = element_line(color = "grey30", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40", size = 10),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

## --- Paths ---
## Derive base_dir from this script's location (code/ is one level below base)
code_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)
base_dir <- dirname(code_dir)
data_dir <- file.path(base_dir, "data")
fig_dir  <- file.path(base_dir, "figures")
tab_dir  <- file.path(base_dir, "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base dir:", base_dir, "\n")
