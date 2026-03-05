## ============================================================================
## 00_packages.R — Load packages and set themes
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# API access
library(httr2)
library(jsonlite)

# NOMIS access
options(repos = c(CRAN = "https://cloud.r-project.org"))
# nomisr not available for R 4.5; use direct API calls via httr2 instead

# Econometrics
library(fixest)       # Fast fixed effects estimation
library(did)          # Callaway & Sant'Anna
library(modelsummary) # Table formatting

# Visualization
library(ggplot2)
library(scales)
library(patchwork)

# Sensitivity
if (!requireNamespace("HonestDiD", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("asheshrambachan/HonestDiD")
}
library(HonestDiD)

# ODS file reading (for CQC data)
if (!requireNamespace("readODS", quietly = TRUE)) install.packages("readODS", type = "source")
library(readODS)

# Set theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
