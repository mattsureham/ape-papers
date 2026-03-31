# 01_fetch_data.R — Fetch Eurostat aviation data for apep_1184
# EU Airport Slot Waivers and Competition

source("00_packages.R")

cat("=== Fetching Eurostat aviation data ===\n")

# ─────────────────────────────────────────────────────────────────────
# 1. Annual passenger data by airport (avia_paoa)
#    Dimensions: freq, unit, tra_meas, rep_airp, schedule, tra_cov, time
#    Filter to: Annual, passengers carried, total schedule, total coverage
# ─────────────────────────────────────────────────────────────────────

# Fetch total passengers by airport (all years available)
cat("Fetching avia_paoa — total passengers carried, annual...\n")
avia_total <- eurostat::get_eurostat_json("avia_paoa",
  filters = list(
    freq = "A",
    unit = "PAS",
    tra_meas = "PAS_CRD",
    schedule = "TOT",
    tra_cov = "TOTAL"
  )
)
stopifnot("FATAL: No annual passenger data" = !is.null(avia_total) && nrow(avia_total) > 0)
cat(sprintf("  Total passengers (annual): %d rows, %d airports\n",
    nrow(avia_total), length(unique(avia_total$rep_airp))))

# Fetch scheduled vs non-scheduled split (for charter placebo)
cat("Fetching avia_paoa — scheduled passengers, annual...\n")
avia_sched <- eurostat::get_eurostat_json("avia_paoa",
  filters = list(
    freq = "A",
    unit = "PAS",
    tra_meas = "PAS_CRD",
    schedule = "SCHED",
    tra_cov = "TOTAL"
  )
)
cat(sprintf("  Scheduled passengers: %d rows\n", nrow(avia_sched)))

cat("Fetching avia_paoa — non-scheduled passengers, annual...\n")
avia_nonsched <- eurostat::get_eurostat_json("avia_paoa",
  filters = list(
    freq = "A",
    unit = "PAS",
    tra_meas = "PAS_CRD",
    schedule = "N_SCHED",
    tra_cov = "TOTAL"
  )
)
cat(sprintf("  Non-scheduled passengers: %d rows\n", nrow(avia_nonsched)))

# ─────────────────────────────────────────────────────────────────────
# 2. Quarterly passenger data (avia_paoq or similar)
# ─────────────────────────────────────────────────────────────────────
cat("Fetching quarterly passenger data...\n")
avia_quarterly <- tryCatch({
  eurostat::get_eurostat_json("avia_paoa",
    filters = list(
      freq = "Q",
      unit = "PAS",
      tra_meas = "PAS_CRD",
      schedule = "TOT",
      tra_cov = "TOTAL"
    )
  )
}, error = function(e) {
  cat("  Quarterly not available in avia_paoa:", e$message, "\n")
  NULL
})

if (!is.null(avia_quarterly) && nrow(avia_quarterly) > 0) {
  cat(sprintf("  Quarterly passengers: %d rows\n", nrow(avia_quarterly)))
} else {
  cat("  No quarterly data available — will use annual\n")
}

# ─────────────────────────────────────────────────────────────────────
# 3. Flight movements data (intensive margin)
# ─────────────────────────────────────────────────────────────────────
cat("Fetching avia_paoa — flight counts, annual...\n")
avia_flights <- tryCatch({
  eurostat::get_eurostat_json("avia_paoa",
    filters = list(
      freq = "A",
      unit = "FLIGHT",
      tra_meas = "CAF_PAS",
      schedule = "TOT",
      tra_cov = "TOTAL"
    )
  )
}, error = function(e) {
  cat("  Flight data error:", e$message, "\n")
  NULL
})

if (!is.null(avia_flights) && nrow(avia_flights) > 0) {
  cat(sprintf("  Flights: %d rows\n", nrow(avia_flights)))
}

# ─────────────────────────────────────────────────────────────────────
# 4. Save raw data
# ─────────────────────────────────────────────────────────────────────
saveRDS(avia_total, "../data/avia_total_annual.rds")
saveRDS(avia_sched, "../data/avia_sched_annual.rds")
saveRDS(avia_nonsched, "../data/avia_nonsched_annual.rds")

if (!is.null(avia_quarterly) && nrow(avia_quarterly) > 0) {
  saveRDS(avia_quarterly, "../data/avia_quarterly.rds")
}
if (!is.null(avia_flights) && nrow(avia_flights) > 0) {
  saveRDS(avia_flights, "../data/avia_flights_annual.rds")
}

# ─────────────────────────────────────────────────────────────────────
# 5. Summary
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("Annual total passengers: %d rows, %d airports\n",
    nrow(avia_total), length(unique(avia_total$rep_airp))))
cat(sprintf("Scheduled passengers: %d rows\n", nrow(avia_sched)))
cat(sprintf("Non-scheduled passengers: %d rows\n", nrow(avia_nonsched)))
cat(sprintf("Time range: %s to %s\n",
    min(avia_total$time, na.rm = TRUE), max(avia_total$time, na.rm = TRUE)))
cat(sprintf("Top airports by 2019 passengers:\n"))

dt <- data.table::as.data.table(avia_total)
dt[, year := as.integer(time)]
top_2019 <- dt[year == 2019 & !is.na(values),
  .(passengers_M = values / 1e6),
  by = rep_airp][order(-passengers_M)][1:20]
print(top_2019)

cat("\n=== Data fetch complete ===\n")
