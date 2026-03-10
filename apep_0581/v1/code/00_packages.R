# 00_packages.R — Install and load required packages
# APEP-0581: Technology Standards and Facility-Level Pollution

required_packages <- c(
  "data.table", "fixest", "did", "ggplot2", "scales",
  "httr2", "jsonlite", "eurostat", "dplyr", "tidyr",
  "stringr", "lubridate", "purrr",
  "knitr", "kableExtra", "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Set global options
options(scipen = 999)
setDTthreads(parallel::detectCores())

# APEP theme for figures
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40", size = base_size),
      axis.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      plot.caption = element_text(color = "grey50", size = base_size - 2)
    )
}

cat("All packages loaded successfully.\n")
