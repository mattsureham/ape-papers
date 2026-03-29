# =============================================================================
# 00_packages.R — Load and install required packages
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================

required <- c(
  "duckdb", "DBI",           # Azure data access
  "data.table",              # Fast data manipulation
  "fixest",                  # Fixed effects estimation
  "sandwich", "lmtest",     # Robust SEs
  "modelsummary",            # Regression tables
  "xtable",                  # LaTeX table output
  "jsonlite",                # diagnostics.json
  "httr", "readr"            # API data fetching
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Force-parse .env to get full Azure connection string
# (Shell source truncates at semicolons)
.apep_force_env <- function() {
  env_candidates <- c(".env", "../.env", "../../.env", "../../../.env",
                      "../../../../.env", "../../../../../.env")
  env_file <- NULL
  for (f in env_candidates) {
    if (file.exists(f)) { env_file <- normalizePath(f); break }
  }
  if (is.null(env_file)) stop("Cannot find .env file")

  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    line <- sub("^export\\s+", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- substr(line, 1, eq_pos - 1)
      val <- substr(line, eq_pos + 1, nchar(line))
      val <- gsub('^["\'](.*)["\']$', "\\1", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}
.apep_force_env()

cat("Packages loaded. R version:", R.version.string, "\n")
cat("Azure configured:", nchar(Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")) > 50, "\n")
