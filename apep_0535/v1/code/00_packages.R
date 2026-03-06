# ==============================================================================
# 00_packages.R — Load required packages and set global options
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

# CRAN packages
pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects (TWFE comparison)
  "did",          # Callaway-Sant'Anna staggered DiD
  "data.table",   # fast data operations
  "haven",        # read .dta files
  "arrow",        # read .feather / .parquet files
  "gtrendsR",     # Google Trends API
  "fredr",        # FRED API
  "jsonlite",     # JSON parsing
  "httr",         # HTTP requests (EIA API)
  "xtable",       # LaTeX table output
  "kableExtra",   # table formatting
  "modelsummary", # regression tables
  "latex2exp",    # LaTeX in plots
  "patchwork",    # combine plots
  "scales",       # axis formatting
  "broom",        # tidy model output
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient tests
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Load .env file from project root
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) > 0 && !startsWith(line, "#") && grepl("=", line)) {
      key <- sub("=.*", "", line)
      val <- sub("^[^=]+=", "", line)
      val <- gsub("^[\"']|[\"']$", "", val)  # strip quotes
      if (key == "export") next
      key <- sub("^export\\s+", "", key)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env from project root.\n")
}

# Set FRED API key
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) > 0) {
  fredr_set_key(fred_key)
  cat("FRED API key set.\n")
} else {
  stop("FRED_API_KEY not found in environment or .env file.")
}

# Global options
options(scipen = 999)
set.seed(42)

# APEP standard theme
theme_apep <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10, color = "grey30"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
      plot.margin = margin(10, 15, 10, 10)
    )
}

apep_colors <- c(
  "#0072B2",  # Blue (treated)
  "#D55E00",  # Orange (control)
  "#009E73",  # Green
  "#CC79A7",  # Pink
  "#F0E442",  # Yellow
  "#56B4E9"   # Light blue
)

cat("Packages loaded successfully.\n")
