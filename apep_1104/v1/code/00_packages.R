# ── 00_packages.R ──────────────────────────────────────────────────
# Install and load required packages for the 14th FC paper
# ───────────────────────────────────────────────────────────────────

required_pkgs <- c(
  "data.table",   # Memory-efficient data ops (8GB RAM constraint)
  "fixest",       # Fast FE estimation with cluster SEs
  "ggplot2",      # Plotting (event study)
  "jsonlite",     # Write diagnostics.json
  "xtable",       # LaTeX table output
  "modelsummary"  # Regression tables
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
