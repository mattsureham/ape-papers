## 00_packages.R
## Load required packages for the regulatory ratchet analysis
## Paper: The Regulatory Ratchet — Media Salience and Asymmetric Federal Rulemaking

# CRAN packages
required_packages <- c(
  # Data manipulation
  "data.table", "dplyr", "tidyr", "stringr", "lubridate",
  # Econometrics
  "fixest",        # Fast fixed effects (feols, feiv)
  "AER",           # IV regression (ivreg)
  "sandwich",      # Cluster-robust SEs
  "lmtest",        # Coefficient tests
  "boot",          # Wild cluster bootstrap
  "clubSandwich",  # Small-cluster robust SEs (CR2)
  "car",           # Wald tests, linearHypothesis
  # Tables and figures
  "ggplot2", "ggthemes", "scales", "patchwork",
  "modelsummary", "knitr", "kableExtra",
  # Utilities
  "readxl", "jsonlite", "httr", "curl", "writexl"
)

# Install missing packages
new_pkgs <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if (length(new_pkgs) > 0) {
  message("Installing missing packages: ", paste(new_pkgs, collapse=", "))
  install.packages(new_pkgs, repos="https://cloud.r-project.org", quiet=TRUE)
}

# Load all packages
suppressPackageStartupMessages({
  for (pkg in required_packages) {
    library(pkg, character.only = TRUE)
  }
})

# Global ggplot theme (AER-style)
theme_apep <- function(base_size=11) {
  theme_bw(base_size=base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color="grey90", linewidth=0.3),
      strip.background = element_rect(fill="grey95", color="grey70"),
      legend.position = "bottom",
      plot.title = element_text(face="bold", size=base_size),
      axis.title = element_text(size=base_size-1)
    )
}
theme_set(theme_apep())

# Agency labels for plots
AGENCY_LABELS <- c(
  "EPA"   = "EPA (Environmental)",
  "OSHA"  = "OSHA (Labor Safety)",
  "FDA"   = "FDA (Food & Drug)",
  "NHTSA" = "NHTSA (Auto Safety)",
  "FAA"   = "FAA (Aviation)",
  "FRA"   = "FRA (Railroad)",
  "MSHA"  = "MSHA (Mining Safety)",
  "CPSC"  = "CPSC (Consumer Products)",
  "FMCSA" = "FMCSA (Trucking)",
  "PHMSA" = "PHMSA (Pipeline)",
  "NRC"   = "NRC (Nuclear)",
  "CFTC"  = "CFTC (Financial Derivatives)"
)

# Color palette
AGENCY_COLORS <- c(
  "EPA"   = "#1b7837",
  "OSHA"  = "#d73027",
  "FDA"   = "#4575b4",
  "NHTSA" = "#f46d43",
  "FAA"   = "#91bfdb",
  "FRA"   = "#8073ac",
  "MSHA"  = "#e08214",
  "CPSC"  = "#a50026",
  "FMCSA" = "#fee090",
  "PHMSA" = "#762a83",
  "NRC"   = "#1a9850",
  "CFTC"  = "#74add1"
)

message("Packages loaded successfully.")
