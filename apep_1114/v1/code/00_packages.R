## 00_packages.R — Load and install required packages for apep_1114
## Dutch Piekbelasters Buyout: Adverse Selection in Environmental Farm Exits

required_packages <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fast fixed-effects estimation
  "cbsodataR",    # CBS Open Data API (Netherlands)
  "sf",           # spatial data (Natura 2000 boundaries)
  "data.table",   # efficient data operations
  "jsonlite",     # JSON output for diagnostics
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("cbsodataR version:", as.character(packageVersion("cbsodataR")), "\n")
