## 00_packages.R — Panic of 1907 + MLP occupational scarring

required_pkgs <- c(
  "tidyverse", "fixest", "data.table", "DBI", "duckdb",
  "jsonlite", "modelsummary", "kableExtra"
)
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  library(pkg, character.only = TRUE)
}

# Load Azure connection with proper .env parsing
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq <- regexpr("=", line, fixed = TRUE)
  if (eq > 0) {
    key <- substr(line, 1, eq - 1)
    val <- substr(line, eq + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}
source("../../../../scripts/lib/azure_data.R")

cat("Packages loaded. Azure:", apep_azure_available(), "\n")
