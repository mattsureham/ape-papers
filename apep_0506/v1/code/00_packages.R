## =============================================================================
## 00_packages.R — Load libraries and set themes
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

# --- Core data manipulation ---
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(haven)     # for reading .dta files

# --- Econometrics ---
library(rdrobust)  # RDD estimation (Calonico, Cattaneo, Titiunik)
library(rddensity) # McCrary density test
library(fixest)    # fast fixed-effects regression
library(sandwich)  # robust standard errors
library(lmtest)    # coefficient tests

# --- Spatial/GIS ---
library(sf)        # simple features for GIS
library(terra)     # raster processing (nightlights)

# --- Visualization ---
library(ggplot2)
library(ggthemes)
library(patchwork) # combining plots
library(scales)
library(kableExtra) # table formatting

# --- Utilities ---
library(httr)      # API calls
library(jsonlite)  # JSON parsing
library(rvest)     # web scraping

# --- Theme ---
theme_set(theme_minimal(base_size = 11) +
            theme(
              panel.grid.minor = element_blank(),
              plot.title = element_text(face = "bold", size = 12),
              plot.subtitle = element_text(color = "gray40"),
              axis.title = element_text(size = 10),
              legend.position = "bottom"
            ))

cat("All packages loaded successfully.\n")
