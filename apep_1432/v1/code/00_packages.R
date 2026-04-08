## 00_packages.R — Load required libraries
## apep_1432: Protests and Campaign Contributions (Weather IV)

## Load .env file
env_file <- file.path(Sys.getenv("HOME"), "auto-policy-evals", ".env")
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub("^[\"']|[\"']$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env file.\n")
}

required <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # IV / 2SLS with fixed effects
  "data.table",   # fast I/O
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "lubridate",    # date handling
  "geosphere",    # distance calculations (station matching)
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
