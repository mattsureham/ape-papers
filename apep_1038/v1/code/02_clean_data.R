# 02_clean_data.R — Clean TRI data and construct facility-year panel
# Treatment: first reporting year >= 1998 (expansion entrant) vs < 1998 (incumbent)

library(data.table)

if (requireNamespace("here", quietly = TRUE)) setwd(here::here()) else setwd(dirname(dirname(sys.frame(1)$ofile)))

# -----------------------------------------------------------------
# 1. Load form data from available year files
# -----------------------------------------------------------------
cat("=== Loading form data ===\n")

form_files <- list.files("data", pattern = "^forms_\\d{4}\\.csv$", full.names = TRUE)
if (length(form_files) == 0) stop("No form data files found in data/")

forms_list <- lapply(form_files, function(f) {
  dt <- fread(f, select = c("tri_facility_id", "tri_chem_id", "reporting_year"))
  yr <- as.integer(gsub(".*forms_(\\d{4})\\.csv", "\\1", f))
  dt[, year := yr]
  dt
})
forms <- rbindlist(forms_list)
cat("Total form records:", nrow(forms), "\n")
cat("Years:", paste(sort(unique(forms$year)), collapse = ", "), "\n")

# -----------------------------------------------------------------
# 2. Build facility-year panel
# -----------------------------------------------------------------
cat("\n=== Building facility-year panel ===\n")

# Count chemicals per facility-year
fac_yr <- forms[, .(n_chemicals = .N), by = .(tri_facility_id, year)]

# Determine first reporting year for each facility
first_yr <- fac_yr[, .(first_year = min(year)), by = tri_facility_id]
fac_yr <- merge(fac_yr, first_yr, by = "tri_facility_id")

# Classify: new entrant (first report >= 1998) vs incumbent (first report < 1998)
fac_yr[, new_entrant := as.integer(first_year >= 1998)]
fac_yr[, post_1998 := as.integer(year >= 1998)]
fac_yr[, treated := as.integer(new_entrant == 1 & post_1998 == 1)]

# Numeric facility ID
fac_yr[, fac_id := as.integer(factor(tri_facility_id))]

# Merge state info from facility metadata
fac_meta <- fread("data/tri_facilities.csv", select = c("tri_facility_id", "state_abbr", "county_name"))
fac_meta <- unique(fac_meta, by = "tri_facility_id")
fac_yr <- merge(fac_yr, fac_meta, by = "tri_facility_id", all.x = TRUE)

cat("New entrants (first report >= 1998):", uniqueN(fac_yr[new_entrant == 1]$tri_facility_id), "\n")
cat("Incumbents (first report < 1998):", uniqueN(fac_yr[new_entrant == 0]$tri_facility_id), "\n")
cat("Observations:", nrow(fac_yr), "\n")
cat("States:", uniqueN(fac_yr$state_abbr), "\n")

# -----------------------------------------------------------------
# 3. Aggregate trends
# -----------------------------------------------------------------
cat("\n=== Aggregate trends ===\n")
agg <- fac_yr[, .(
  n_facilities = uniqueN(tri_facility_id),
  n_forms = sum(n_chemicals),
  mean_chemicals = mean(n_chemicals)
), by = .(year, new_entrant)]

cat("New entrants by year:\n")
print(agg[new_entrant == 1][order(year)])
cat("\nIncumbents by year:\n")
print(agg[new_entrant == 0][order(year)])

# Also load the full aggregate counts
full_counts <- tryCatch({
  jsonlite::fromJSON("data/form_counts_by_year.json")
}, error = function(e) NULL)

if (!is.null(full_counts)) {
  cat("\n=== Full aggregate counts (1987-2006) ===\n")
  counts_dt <- data.table(
    year = as.integer(names(full_counts)),
    total_forms = as.integer(unlist(full_counts))
  )[order(year)]
  print(counts_dt)
  fwrite(counts_dt, "data/aggregate_counts.csv")
}

# -----------------------------------------------------------------
# 4. Save analysis panel
# -----------------------------------------------------------------
fwrite(fac_yr, "data/analysis_panel.csv")

# Diagnostics for validator
diag <- list(
  n_treated = uniqueN(fac_yr[new_entrant == 1]$tri_facility_id),
  n_pre = length(unique(fac_yr[year < 1998]$year)),
  n_obs = nrow(fac_yr)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== CLEAN DATA SAVED ===\n")
cat("Treated (new entrants):", diag$n_treated, "\n")
cat("Pre-treatment years:", diag$n_pre, "\n")
cat("Observations:", diag$n_obs, "\n")
