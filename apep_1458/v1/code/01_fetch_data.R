source("00_packages.R")

cat("=== Fetching EPA SDWIS data ===\n")

base_url <- "https://data.epa.gov/efservice"

fetch_csv <- function(endpoint, batch_size = 5000, max_rows = Inf) {
  all_data <- list()
  offset <- 0
  repeat {
    url <- paste0(base_url, "/", endpoint, "/ROWS/", offset, ":", offset + batch_size - 1, "/CSV")
    cat("  Fetching rows", offset, "-", offset + batch_size - 1, "...\n")
    resp <- tryCatch(
      GET(url, timeout(600)),
      error = function(e) { cat("  Network error:", e$message, "\n"); NULL }
    )
    if (is.null(resp) || status_code(resp) != 200) {
      cat("  Failed (HTTP", if (!is.null(resp)) status_code(resp) else "timeout", ")\n")
      break
    }
    txt <- content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) < 50) break
    batch <- tryCatch(
      read_csv(txt, show_col_types = FALSE, col_types = cols(.default = col_character())),
      error = function(e) { cat("  Parse error:", e$message, "\n"); NULL }
    )
    if (is.null(batch) || nrow(batch) == 0) break
    all_data[[length(all_data) + 1]] <- batch
    cat("    Got", nrow(batch), "rows\n")
    offset <- offset + batch_size
    if (offset >= max_rows) break
    if (nrow(batch) < batch_size) break
    Sys.sleep(1)
  }
  if (length(all_data) == 0) {
    warning("No data fetched from ", endpoint)
    return(tibble())
  }
  bind_rows(all_data)
}

# --- Systems by population category ---
cat("\n--- Water Systems (CWS, active, by pop category) ---\n")
sys_parts <- list()
for (cat_code in 1:5) {
  cat("\n  Pop category", cat_code, ":\n")
  sys_parts[[cat_code]] <- tryCatch(
    fetch_csv(paste0("WATER_SYSTEM/PWS_TYPE_CODE/CWS/PWS_ACTIVITY_CODE/A/POP_CAT_5_CODE/", cat_code)),
    error = function(e) { cat("  Error:", e$message, "\n"); tibble() }
  )
}
systems <- bind_rows(compact(sys_parts))
cat("\nTotal active CWS systems:", nrow(systems), "\n")
stopifnot(nrow(systems) > 5000)

# --- Violations: use broader filter, then subset in R ---
cat("\n--- Health-based violations (CWS) ---\n")
viol_health <- fetch_csv("VIOLATION/IS_HEALTH_BASED_IND/Y/PWS_TYPE_CODE/CWS", max_rows = 300000)
cat("  Health-based violations fetched:", nrow(viol_health), "\n")

cat("\n--- Monitoring violations (coliform rule family 200) ---\n")
viol_mon <- fetch_csv("VIOLATION/VIOLATION_CATEGORY_CODE/MON/RULE_FAMILY_CODE/220/PWS_TYPE_CODE/CWS",
                       max_rows = 200000)
if (nrow(viol_mon) == 0) {
  cat("  Trying alternative endpoint for monitoring violations...\n")
  viol_mon <- fetch_csv("VIOLATION/VIOLATION_CATEGORY_CODE/MON/PWS_TYPE_CODE/CWS", max_rows = 200000)
}
cat("  Monitoring violations fetched:", nrow(viol_mon), "\n")

cat("\n--- MCL violations (CWS) ---\n")
viol_mcl <- fetch_csv("VIOLATION/VIOLATION_CATEGORY_CODE/MCL/PWS_TYPE_CODE/CWS", max_rows = 300000)
cat("  MCL violations fetched:", nrow(viol_mcl), "\n")

saveRDS(systems, "../data/water_systems.rds")
saveRDS(viol_health, "../data/violations_health.rds")
saveRDS(viol_mon, "../data/violations_mon.rds")
saveRDS(viol_mcl, "../data/violations_mcl.rds")

cat("\n=== Data fetch complete ===\n")
cat("Systems:", nrow(systems), "\n")
cat("Health-based violations:", nrow(viol_health), "\n")
cat("Monitoring violations:", nrow(viol_mon), "\n")
cat("MCL violations:", nrow(viol_mcl), "\n")
