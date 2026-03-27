# 01_fetch_data.R — Fetch EPA SDWIS data via Envirofacts REST API
# apep_1057: The Consolidation Trap
# Strategy: fetch state-by-state, save incrementally

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# EPA Envirofacts API helper
# ============================================================================
fetch_epa <- function(table, params, rows_start = 0, rows_end = 9999) {
  base_url <- "https://data.epa.gov/efservice"
  url <- paste0(base_url, "/", table, "/", params,
                "/rows/", rows_start, ":", rows_end, "/JSON")
  resp <- GET(url, timeout(180))
  if (status_code(resp) != 200) {
    stop("EPA API returned status ", status_code(resp))
  }
  txt <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(txt) < 10) return(data.frame())
  fromJSON(txt, flatten = TRUE)
}

fetch_epa_all <- function(table, params, batch_size = 10000, max_rows = 500000) {
  all_data <- list()
  offset <- 0
  repeat {
    chunk <- tryCatch(
      fetch_epa(table, params, offset, offset + batch_size - 1),
      error = function(e) {
        cat("    Error at offset", offset, ":", conditionMessage(e), "\n")
        NULL
      }
    )
    if (is.null(chunk) || !is.data.frame(chunk) || nrow(chunk) == 0) break
    all_data[[length(all_data) + 1]] <- chunk
    offset <- offset + batch_size
    if (offset >= max_rows) break
    if (nrow(chunk) < batch_size) break
    Sys.sleep(0.3)
  }
  if (length(all_data) == 0) return(data.frame())
  bind_rows(all_data)
}

# ============================================================================
# 1. Fetch all CWS (active + inactive) by state
# ============================================================================
cat("=== Fetching Community Water Systems ===\n")

# Use all US states + DC + territories
states <- c(state.abb, "DC", "PR", "VI", "GU", "AS", "MP")

systems_file <- file.path(data_dir, "water_systems_raw.csv")
if (file.exists(systems_file)) {
  cat("Systems file exists, loading cached version.\n")
  systems_raw <- fread(systems_file)
} else {
  all_systems <- list()
  for (st in states) {
    cat("  ", st, "... ")
    tryCatch({
      df <- fetch_epa_all("WATER_SYSTEM",
                           paste0("PWS_TYPE_CODE/CWS/STATE_CODE/", st),
                           batch_size = 10000, max_rows = 50000)
      if (nrow(df) > 0) {
        all_systems[[st]] <- df
        cat(nrow(df), "systems\n")
      } else {
        cat("0 systems\n")
      }
    }, error = function(e) {
      cat("FAILED:", conditionMessage(e), "\n")
    })
    Sys.sleep(0.3)
  }
  systems_raw <- bind_rows(all_systems)
  cat("\nTotal CWS:", nrow(systems_raw), "\n")

  if (nrow(systems_raw) < 50000) {
    stop("FATAL: Expected >50,000 CWS but got ", nrow(systems_raw))
  }
  fwrite(systems_raw, systems_file)
  cat("Saved water_systems_raw.csv\n")
}

# ============================================================================
# 2. Fetch health-based violations by state
# ============================================================================
cat("\n=== Fetching Health-Based Violations ===\n")

violations_file <- file.path(data_dir, "violations_raw.csv")
if (file.exists(violations_file)) {
  cat("Violations file exists, loading cached version.\n")
  violations_raw <- fread(violations_file)
} else {
  all_violations <- list()
  for (st in states) {
    cat("  ", st, "... ")
    tryCatch({
      df <- fetch_epa_all("VIOLATION",
                           paste0("IS_HEALTH_BASED_IND/Y/STATE_CODE/", st),
                           batch_size = 10000, max_rows = 500000)
      if (nrow(df) > 0) {
        all_violations[[st]] <- df
        cat(nrow(df), "violations\n")
      } else {
        cat("0 violations\n")
      }
    }, error = function(e) {
      cat("FAILED:", conditionMessage(e), "\n")
    })
    Sys.sleep(0.3)
  }
  violations_raw <- bind_rows(all_violations)
  cat("\nTotal violations:", nrow(violations_raw), "\n")

  if (nrow(violations_raw) < 50000) {
    stop("FATAL: Expected >50,000 violations but got ", nrow(violations_raw))
  }
  fwrite(violations_raw, violations_file)
  cat("Saved violations_raw.csv\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Systems:", nrow(systems_raw), "\n")
cat("Violations:", nrow(violations_raw), "\n")
