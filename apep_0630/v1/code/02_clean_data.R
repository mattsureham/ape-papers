## 02_clean_data.R — Construct analysis variables
## apep_0630: Surprise Billing Laws and ED Quality

library(data.table)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "."
setwd(file.path(script_dir, ".."))

tec <- fread("data/ed_measures_panel.csv")
hosp <- fread("data/hospital_info.csv")

# Ensure provider_id is character everywhere
tec[, provider_id := as.character(provider_id)]
hosp[, provider_id := as.character(provider_id)]

# ---- Extract measurement year from date fields ----
# Each NBER release contains data measured ~1-2 years before release.
# Parse end_date to extract the year. Handle both "MM/DD/YYYY" and "YYYY-MM-DD".

tec[, end_date_str := as.character(end_date)]

# Try YYYY-MM-DD first
tec[, end_year := as.integer(substr(end_date_str, 1, 4))]
# Fix cases where first 4 chars aren't a valid year (MM/DD/YYYY format)
tec[is.na(end_year) | end_year < 2000, end_year := as.integer(
  sub(".*/", "", end_date_str)  # Extract year after last "/"
)]

# Fallback: use release_year - 1 if still missing
tec[is.na(end_year), end_year := release_year - 1L]

tec[, meas_year := end_year]

cat("Measurement year distribution:\n")
print(table(tec$meas_year, tec$measure_id, useNA = "always"))

# ---- Surprise billing law treatment coding ----
surprise_billing <- data.table(
  state = c("NY", "CT", "FL", "CA", "IL", "MD", "NH", "NJ", "OR"),
  law_year = c(2015L, 2015L, 2016L, 2017L, 2018L, 2018L, 2018L, 2018L, 2018L),
  law_name = c(
    "Emergency Medical Services and Surprise Bills Law",
    "PA 15-146 OON Billing Protections",
    "HB 221 Balance Billing Protections",
    "AB 72 Out-of-Network Coverage",
    "HB 3978 Balance Billing Protection",
    "HB 1122 Balance Billing Protections",
    "HB 1809 OON Billing Protections",
    "P.L. 2018 c.32 OON Protections",
    "HB 2339 Surprise Billing Protections"
  )
)

# Merge treatment info
tec <- merge(tec, surprise_billing[, .(state, law_year)],
             by = "state", all.x = TRUE)
tec[is.na(law_year), law_year := 0L]

# G (first treatment period) for Callaway-Sant'Anna
tec[, G := law_year]
tec[, treated := as.integer(law_year > 0 & meas_year >= law_year)]

# ---- Reshape to hospital-year panel ----
op18b <- tec[measure_id == "OP_18b",
             .(provider_id, state, meas_year, release_year, G, law_year,
               treated, ed_time = score, ed_time_sample = sample)]

op22 <- tec[measure_id == "OP_22",
            .(provider_id, meas_year,
              lwbs_pct = score, lwbs_sample = sample)]

# Merge outcomes
panel <- merge(op18b, op22[, .(provider_id, meas_year, lwbs_pct, lwbs_sample)],
               by = c("provider_id", "meas_year"), all.x = TRUE)

# ---- Merge hospital characteristics ----
hosp_latest <- hosp[order(release_year), .SD[.N], by = provider_id]

panel <- merge(panel, hosp_latest[, .(provider_id, hospital_type, ownership, emergency)],
               by = "provider_id", all.x = TRUE)

# ---- Filter sample ----
panel <- panel[hospital_type == "Acute Care Hospitals" | is.na(hospital_type)]
panel <- panel[emergency == "Yes" | is.na(emergency)]

# Drop territories
territories <- c("AS", "GU", "MH", "MP", "PR", "VI", "DC")
panel <- panel[!state %in% territories]

# Require valid ED time score
panel <- panel[!is.na(ed_time)]

# ---- Ownership classification ----
panel[, ownership_type := fcase(
  grepl("Voluntary|non-profit|Nonprofit", ownership, ignore.case = TRUE), "Nonprofit",
  grepl("Proprietary|for-profit|profit", ownership, ignore.case = TRUE), "For-profit",
  grepl("Government", ownership, ignore.case = TRUE), "Government",
  default = "Other"
)]

# ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Hospitals: %d\n", uniqueN(panel$provider_id)))
cat(sprintf("States: %d\n", uniqueN(panel$state)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$meas_year)), collapse = ", ")))
cat(sprintf("Hospital-years: %d\n", nrow(panel)))
cat(sprintf("Treated states: %s\n", paste(sort(unique(panel[G > 0]$state)), collapse = ", ")))
cat(sprintf("Treated hospitals: %d\n", uniqueN(panel[G > 0]$provider_id)))
cat(sprintf("Never-treated hospitals: %d\n", uniqueN(panel[G == 0]$provider_id)))
cat(sprintf("\nED time (OP_18b): Mean=%.1f, SD=%.1f, Min=%.0f, Max=%.0f\n",
            mean(panel$ed_time, na.rm = TRUE),
            sd(panel$ed_time, na.rm = TRUE),
            min(panel$ed_time, na.rm = TRUE),
            max(panel$ed_time, na.rm = TRUE)))
cat(sprintf("LWBS (OP_22): Mean=%.1f, SD=%.1f, N=%d\n",
            mean(panel$lwbs_pct, na.rm = TRUE),
            sd(panel$lwbs_pct, na.rm = TRUE),
            sum(!is.na(panel$lwbs_pct))))

cat("\n=== Cohort Sizes ===\n")
cohort_tab <- panel[, .(n_hospitals = uniqueN(provider_id)), by = .(G)]
print(cohort_tab[order(G)])

cat("\n=== Year x Treatment Status ===\n")
print(panel[, .N, by = .(meas_year, treated)][order(meas_year, treated)])

# ---- Save ----
fwrite(panel, "data/analysis_panel.csv")
cat(sprintf("\nSaved analysis panel: %d rows\n", nrow(panel)))
