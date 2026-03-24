## 00_packages.R — Install and load required packages
## apep_0845: EU Professional Qualifications Directive

required <- c(
  "eurostat",    # Eurostat data access
  "data.table",  # Fast data manipulation
  "fixest",      # Fixed effects estimation (feols, sunab)
  "did",         # Callaway-Sant'Anna DiD
  "ggplot2",     # Plotting (for diagnostics, not paper)
  "sandwich",    # Robust standard errors
  "lmtest",      # Coefficient testing
  "jsonlite",    # JSON output for diagnostics
  "xtable",      # LaTeX table output
  # "fwildclusterboot", # Wild cluster bootstrap — not available for this R version
  "httr",        # HTTP requests for SPARQL
  "xml2"         # XML parsing for SPARQL results
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
