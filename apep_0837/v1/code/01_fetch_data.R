# 01_fetch_data.R — Fetch Eurostat data for R2D analysis
source("00_packages.R")

# ============================================================================
# 1. Long working hours (>48h/week) by occupation — lfsa_qoe_3a2
# ============================================================================
cat("Fetching lfsa_qoe_3a2 (long working hours by occupation)...\n")
long_hours_raw <- get_eurostat("lfsa_qoe_3a2", time_format = "num")

if (is.null(long_hours_raw) || nrow(long_hours_raw) == 0) {
  stop("FATAL: Eurostat lfsa_qoe_3a2 returned no data. Cannot proceed.")
}
cat(sprintf("  lfsa_qoe_3a2: %d rows fetched\n", nrow(long_hours_raw)))

# ============================================================================
# 2. Usual weekly hours by occupation (full-time) — lfsa_ewhais
# ============================================================================
cat("Fetching lfsa_ewhais (usual weekly hours by occupation)...\n")
usual_hours_raw <- get_eurostat("lfsa_ewhais", time_format = "num")

if (is.null(usual_hours_raw) || nrow(usual_hours_raw) == 0) {
  stop("FATAL: Eurostat lfsa_ewhais returned no data. Cannot proceed.")
}
cat(sprintf("  lfsa_ewhais: %d rows fetched\n", nrow(usual_hours_raw)))

# ============================================================================
# 3. Self-perceived health — hlth_silc_17
# ============================================================================
cat("Fetching hlth_silc_17 (self-perceived health)...\n")
health_raw <- tryCatch(
  get_eurostat("hlth_silc_17", time_format = "num"),
  error = function(e) {
    warning(sprintf("hlth_silc_17 fetch failed: %s — will proceed without health outcome", e$message))
    NULL
  }
)
if (!is.null(health_raw)) {
  cat(sprintf("  hlth_silc_17: %d rows fetched\n", nrow(health_raw)))
} else {
  cat("  hlth_silc_17: skipped (fetch error)\n")
}

# ============================================================================
# Save raw data
# ============================================================================
saveRDS(long_hours_raw, "../data/long_hours_raw.rds")
saveRDS(usual_hours_raw, "../data/usual_hours_raw.rds")
if (!is.null(health_raw)) saveRDS(health_raw, "../data/health_raw.rds")

cat("Data fetch complete.\n")
