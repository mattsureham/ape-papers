## ── 00_packages.R ──────────────────────────────────────────────
## Load and install required packages for DMF analysis
## ────────────────────────────────────────────────────────────────

required <- c("data.table", "fixest", "ggplot2", "jsonlite", "xtable", "stargazer")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
