## 00_packages.R — Load and install required packages
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

required_packages <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fast fixed effects estimation
  "eurostat",     # Eurostat API access
  "modelsummary", # regression tables
  "jsonlite",     # diagnostics output
  "kableExtra",   # table formatting
  # "fwildclusterboot", # wild cluster bootstrap — not available for this R version
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
