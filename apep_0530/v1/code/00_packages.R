## 00_packages.R — Load libraries and set themes
## QPV/ZUS zone redesignation and property values

if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
if (!requireNamespace("data.table", quietly = TRUE)) install.packages("data.table")
if (!requireNamespace("fixest", quietly = TRUE)) install.packages("fixest")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("rdrobust", quietly = TRUE)) install.packages("rdrobust")
if (!requireNamespace("modelsummary", quietly = TRUE)) install.packages("modelsummary")
if (!requireNamespace("kableExtra", quietly = TRUE)) install.packages("kableExtra")

library(sf)
library(data.table)
library(fixest)
library(ggplot2)
library(rdrobust)
library(modelsummary)
library(kableExtra)

theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40")
  ))

cat("All packages loaded.\n")
