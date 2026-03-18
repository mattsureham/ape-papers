## 00_packages.R — Load and verify required packages
## apep_0721: UK NLW Wage Distribution Compression

required_pkgs <- c(
  "tidyverse",    # Data wrangling
  "fixest",       # Fixed effects estimation
  "jsonlite",     # JSON output for diagnostics
  "kableExtra"    # Table formatting
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
