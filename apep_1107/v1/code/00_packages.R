## 00_packages.R — Load and install required packages
## apep_1107: Romania Overnight Payroll Tax Shift

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "eurostat",     # Eurostat REST API
  "fixest",       # fast fixed effects
  "Synth",        # synthetic control method
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics output
  "xtable"        # LaTeX tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
