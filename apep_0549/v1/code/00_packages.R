## =============================================================================
## 00_packages.R — Online Sports Betting and Alcohol-Involved Fatal Crashes
## =============================================================================

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)
library(purrr)

# Econometrics
library(fixest)      # High-dimensional FE, cluster SEs
library(did)         # Callaway-Sant'Anna
library(HonestDiD)   # Rambachan-Roth sensitivity

# Visualization
library(ggplot2)
library(scales)
library(patchwork)

# Tables
library(modelsummary)
library(kableExtra)

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 11, base_family = "serif") +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
