## 00_packages.R — Load and install required packages
## apep_0830: VAT Receipt Lotteries and Compliance Gaps

pkgs <- c(
  "tidyverse",
  "fixest",
  "did",
  "eurostat",
  "jsonlite",
  "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# DIDmultiplegtDYN has an rgl dependency that may fail on macOS without X11
# Try to load it; if it fails, we'll use alternative approaches
dcdh_available <- tryCatch({
  if (!requireNamespace("DIDmultiplegtDYN", quietly = TRUE)) {
    install.packages("DIDmultiplegtDYN", repos = "https://cloud.r-project.org")
  }
  library(DIDmultiplegtDYN)
  TRUE
}, error = function(e) {
  cat("DIDmultiplegtDYN not available:", e$message, "\n")
  cat("Will use alternative estimator (fixest sunab + manual treatment switching).\n")
  FALSE
})

# fwildclusterboot may not be available for this R version
fwcb_available <- tryCatch({
  if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
    install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  }
  library(fwildclusterboot)
  TRUE
}, error = function(e) {
  cat("fwildclusterboot not available:", e$message, "\n")
  FALSE
})

# HonestDiD
honestdid_available <- tryCatch({
  if (!requireNamespace("HonestDiD", quietly = TRUE)) {
    install.packages("HonestDiD", repos = "https://cloud.r-project.org")
  }
  library(HonestDiD)
  TRUE
}, error = function(e) {
  cat("HonestDiD not available:", e$message, "\n")
  FALSE
})

cat("All packages loaded. DCDH:", dcdh_available, "FWCB:", fwcb_available, "\n")
