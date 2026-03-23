# =============================================================================
# 00_packages.R — Load all required packages
# =============================================================================

required <- c("duckdb", "DBI", "data.table", "fixest", "jsonlite", "xtable")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Helper: Load Azure connection string from .env without semicolon truncation
load_azure_cs <- function() {
  env_paths <- c(".env", "../.env", "../../.env", "../../../.env",
                 "../../../../.env", "../../../../../.env")
  env_file <- NULL
  for (p in env_paths) {
    if (file.exists(p)) { env_file <- normalizePath(p); break }
  }
  if (is.null(env_file)) stop("Cannot find .env file")

  lines <- readLines(env_file, warn = FALSE)
  cs_line <- lines[grepl("^AZURE_STORAGE_CONNECTION_STRING=", lines)][1]
  if (is.na(cs_line)) stop("AZURE_STORAGE_CONNECTION_STRING not found in .env")

  cs <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
  # Remove surrounding quotes if any
  cs <- gsub('^["\'](.*)["\']$', "\\1", cs)
  return(cs)
}

# Create DuckDB connection with Azure
azure_connect <- function() {
  cs <- load_azure_cs()
  con <- dbConnect(duckdb())
  dbExecute(con, "INSTALL azure;")
  dbExecute(con, "LOAD azure;")
  dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", cs))
  message("Connected to Azure (apepdata)")
  return(con)
}

cat("Packages loaded successfully\n")
