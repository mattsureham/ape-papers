## ==========================================================================
## 00_packages.R — Constitutional Carry and Gun Violence
## Load all required packages and set global options
## ==========================================================================

# --- Core data manipulation ---
library(tidyverse)
library(data.table)
library(janitor)

# --- Econometrics ---
library(fixest)        # Fast TWFE, Sun-Abraham
library(did)           # Callaway-Sant'Anna
library(bacondecomp)   # Goodman-Bacon decomposition
library(HonestDiD)     # Rambachan-Roth sensitivity

# --- Inference ---
library(sandwich)
library(lmtest)

# --- Tables and figures ---
library(ggplot2)
library(scales)
library(kableExtra)
library(patchwork)

# --- API access ---
library(httr)
library(jsonlite)

# --- Global options ---
options(scipen = 999)
theme_set(theme_minimal(base_size = 12) +
            theme(panel.grid.minor = element_blank(),
                  plot.title = element_text(face = "bold"),
                  legend.position = "bottom"))

cat("All packages loaded successfully.\n")
