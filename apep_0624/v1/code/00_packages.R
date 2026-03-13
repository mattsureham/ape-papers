# 00_packages.R — Load and install required packages
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

required_packages <- c(
  "tidyverse",
  "fixest",
  "data.table",
  "modelsummary",
  "kableExtra",
  "jsonlite",
  "httr",
  "sandwich",
  "lmtest"
)

# Try optional packages (may not be available for all R versions)
optional_packages <- c("fwildclusterboot", "HonestDiD")
for (pkg in optional_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    library(pkg, character.only = TRUE)
    cat("Loaded optional package:", pkg, "\n")
  } else {
    cat("Optional package not available:", pkg, "\n")
  }
}

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
