## 01_fetch_data.R — Fetch Eurostat SBS data for Romania bunching analysis
## apep_0824

source("00_packages.R")

cat("=== Fetching Eurostat Structural Business Statistics ===\n")

# ---- 1. Primary dataset: enterprise counts by turnover size class ----
# sbs_sc_sca_r2: Annual detailed enterprise statistics - industry and construction
# This has firm counts by turnover size class for each EU country

cat("Fetching SBS enterprise statistics by turnover size class...\n")

# Try the main SBS dataset
sbs_raw <- tryCatch({
  get_eurostat("sbs_sc_sca_r2", time_format = "num")
}, error = function(e) {
  cat("sbs_sc_sca_r2 failed:", e$message, "\n")
  NULL
})

if (is.null(sbs_raw)) {
  cat("Trying alternative dataset ID...\n")
  sbs_raw <- tryCatch({
    get_eurostat("sbs_sc_sca_r2", time_format = "num", filters = list(geo = "RO"))
  }, error = function(e) {
    cat("Filtered fetch also failed:", e$message, "\n")
    NULL
  })
}

# If SBS by size class not available, try sbs_sc_ind_r2 (industry by size)
if (is.null(sbs_raw)) {
  cat("Trying sbs_sc_ind_r2...\n")
  sbs_raw <- tryCatch({
    get_eurostat("sbs_sc_ind_r2", time_format = "num")
  }, error = function(e) {
    cat("sbs_sc_ind_r2 also failed:", e$message, "\n")
    NULL
  })
}

if (is.null(sbs_raw)) {
  stop("FATAL: Cannot fetch any SBS dataset from Eurostat. Aborting — no fallback to simulated data.")
}

cat("SBS raw data: ", nrow(sbs_raw), " rows, ", ncol(sbs_raw), " columns\n")
cat("Variables: ", paste(names(sbs_raw), collapse = ", "), "\n")
cat("Countries: ", paste(sort(unique(sbs_raw$geo)), collapse = ", "), "\n")
cat("Years: ", paste(sort(unique(sbs_raw$time)), collapse = ", "), "\n")

# Check for size class variable
size_vars <- names(sbs_raw)[grepl("size|class", names(sbs_raw), ignore.case = TRUE)]
cat("Size class variables: ", paste(size_vars, collapse = ", "), "\n")

# Check all dimensions
for (v in names(sbs_raw)) {
  uvals <- unique(sbs_raw[[v]])
  if (length(uvals) < 50) {
    cat(v, ":", length(uvals), "values:", paste(head(uvals, 20), collapse = ", "), "\n")
  } else {
    cat(v, ":", length(uvals), "unique values\n")
  }
}

saveRDS(sbs_raw, "../data/sbs_raw.rds")
cat("Saved sbs_raw.rds\n")

# ---- 2. Business demography: births, deaths, survival ----
cat("\nFetching business demography data...\n")

bd_raw <- tryCatch({
  get_eurostat("bd_9ac_l_form_r2", time_format = "num")
}, error = function(e) {
  cat("bd_9ac_l_form_r2 failed:", e$message, "\n")
  # Try alternatives
  tryCatch({
    get_eurostat("bd_9bd_sz_cl_r2", time_format = "num")
  }, error = function(e2) {
    cat("bd_9bd_sz_cl_r2 also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(bd_raw)) {
  cat("Business demography data: ", nrow(bd_raw), " rows\n")
  saveRDS(bd_raw, "../data/bd_raw.rds")
  cat("Saved bd_raw.rds\n")
} else {
  cat("WARNING: No business demography data available. Proceeding with SBS only.\n")
}

# ---- 3. Also fetch enterprise counts by employee size class ----
# This provides a second angle: do firms also bunch in employee counts?
cat("\nFetching SBS data by employee size class...\n")

sbs_emp <- tryCatch({
  get_eurostat("sbs_sc_1b_se_r2", time_format = "num")
}, error = function(e) {
  cat("Employee size class data not available:", e$message, "\n")
  NULL
})

if (!is.null(sbs_emp)) {
  cat("Employee size class data: ", nrow(sbs_emp), " rows\n")
  saveRDS(sbs_emp, "../data/sbs_emp_raw.rds")
} else {
  cat("No employee size class data. Proceeding with turnover data.\n")
}

cat("\n=== Data fetch complete ===\n")
