## ============================================================
## 00_packages.R — Load libraries and set themes
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

## --- Load .env from project root ---
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    if (grepl("^export\\s+", line)) line <- sub("^export\\s+", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      val <- gsub('^["\']|["\']$', '', val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env\n")
}

## --- Core ---
library(tidyverse)
library(data.table)
library(fixest)
library(jsonlite)
library(httr)
library(lubridate)

## --- Econometrics ---
library(did)          # Callaway-Sant'Anna
library(lmtest)       # Coefficient tests
library(sandwich)     # Robust SEs
library(boot)         # Bootstrap

## --- Tables & Figures ---
library(xtable)
library(modelsummary)
library(kableExtra)
library(patchwork)

## --- Set APEP theme ---
theme_apep <- theme_minimal(base_size = 11, base_family = "serif") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(linewidth = 0.3),
    axis.ticks = element_line(linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("Packages loaded. Theme set.\n")
