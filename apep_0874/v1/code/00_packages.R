# ============================================================
# 00_packages.R — Package management for apep_0874
# Feeding the Supply Side: SNAP TFP & Retailer Entry
# ============================================================

required_packages <- c(
  "data.table", "fixest", "dplyr", "tidyr", "stringr",
  "httr", "jsonlite", "readr", "lubridate"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")

# Load .env for API keys
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    line <- sub("^export\\s+", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- substr(line, 1, eq_pos - 1)
      val <- substr(line, eq_pos + 1, nchar(line))
      # Remove surrounding quotes
      val <- gsub('^["\']|["\']$', '', val)
      Sys.setenv(key = val)
      # Use do.call to set named env var
      args <- list(val)
      names(args) <- key
      do.call(Sys.setenv, args)
    }
  }
  cat("Environment loaded from .env\n")
} else {
  cat("WARNING: .env not found at", env_file, "\n")
}
