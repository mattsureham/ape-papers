## ============================================================================
## 00_packages.R — Package loading and theme setup
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

# Core packages
library(tidyverse)
library(data.table)
library(arrow)

# RDD packages
library(rdrobust)
library(rddensity)

# Econometrics
library(fixest)
library(sandwich)
library(lmtest)

# Tables and output
library(modelsummary)
library(kableExtra)
library(xtable)

# Figures
library(ggplot2)
library(patchwork)
library(scales)

# APEP theme for publication-quality figures
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.1)),
      plot.subtitle = element_text(color = "grey40", size = rel(0.9)),
      axis.title = element_text(size = rel(0.95)),
      axis.text = element_text(size = rel(0.85)),
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.85)),
      legend.text = element_text(size = rel(0.8)),
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", size = rel(0.9)),
      plot.caption = element_text(color = "grey50", size = rel(0.7), hjust = 0)
    )
}
theme_set(theme_apep())

# DPE class cutoffs (post-2021 double-seuil system)
# Energy consumption thresholds (kWh/m²/year primary energy)
DPE_ENERGY_CUTS <- c(A = 70, B = 110, C = 180, D = 250, E = 330, F = 420)
# GHG emission thresholds (kg CO2eq/m²/year)
DPE_GHG_CUTS <- c(A = 6, B = 11, C = 30, D = 50, E = 70, F = 100)

# DPE class colors (official French scheme)
DPE_COLORS <- c(
  A = "#319834", B = "#52B946", C = "#8CC631",
  D = "#FFED00", E = "#F8B334", F = "#EF7D23", G = "#D1191F"
)

cat("Packages loaded. DPE cutoffs defined.\n")
cat("Energy cutoffs (kWh/m²/yr):", paste(names(DPE_ENERGY_CUTS), DPE_ENERGY_CUTS, sep = "=", collapse = ", "), "\n")
