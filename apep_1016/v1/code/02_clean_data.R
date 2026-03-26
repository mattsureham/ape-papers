## 02_clean_data.R — Clean data and construct analysis variables
## apep_1016: Fresh Start Dividend

library(tidyverse)
library(data.table)

DATA_DIR <- file.path(dirname(getwd()), "data")

# -----------------------------------------------------------------------
# 1. Load and clean bankruptcy case data
# -----------------------------------------------------------------------

cases <- fread(file.path(DATA_DIR, "courtlistener_ch13_cases.csv"))
cat(sprintf("Loaded %d raw cases\n", nrow(cases)))

# Clean judge names (remove Z-prefix artifacts, standardize)
cases[, judge_clean := str_to_title(str_replace_all(judge_name, "[Zz](?=[A-Z])", ""))]
cases[, judge_clean := str_trim(judge_clean)]
cases[is.na(judge_name) | judge_name == "", judge_clean := NA_character_]

# Drop cases with missing judge
cases <- cases[!is.na(judge_clean)]
cat(sprintf("After dropping missing judges: %d cases\n", nrow(cases)))

# Parse dates
cases[, date_filed := as.Date(date_filed)]
cases[, date_terminated := as.Date(date_terminated)]

# Compute case duration in days
cases[, duration_days := as.numeric(date_terminated - date_filed)]

# Drop cases with missing or negative duration
cases <- cases[!is.na(duration_days) & duration_days > 0]
cat(sprintf("After dropping invalid durations: %d cases\n", nrow(cases)))

# Filing year
cases[, file_year := year(date_filed)]

# -----------------------------------------------------------------------
# 2. Construct proxy outcome: plan confirmed vs dismissed/converted
# -----------------------------------------------------------------------

cases[, confirmed_proxy := as.integer(duration_days > 730)]

cat(sprintf("\nConfirmation proxy distribution:\n"))
cat(sprintf("  Confirmed (>730 days): %d (%.1f%%)\n",
            sum(cases$confirmed_proxy == 1),
            100 * mean(cases$confirmed_proxy == 1)))
cat(sprintf("  Dismissed (<=730 days): %d (%.1f%%)\n",
            sum(cases$confirmed_proxy == 0),
            100 * mean(cases$confirmed_proxy == 0)))
cat(sprintf("  Median duration: %.0f days\n", median(cases$duration_days)))

# -----------------------------------------------------------------------
# 3. Compute judge-level leniency (leave-one-out)
# -----------------------------------------------------------------------

judge_stats <- cases[, .(
  n_cases = .N,
  raw_confirm_rate = mean(confirmed_proxy),
  mean_duration = mean(duration_days)
), by = .(court_id, judge_clean)]

cat(sprintf("\nJudge-level statistics:\n"))
cat(sprintf("  Total judge-court pairs: %d\n", nrow(judge_stats)))
cat(sprintf("  Mean cases per judge: %.0f\n", mean(judge_stats$n_cases)))
cat(sprintf("  Confirmation rate range: [%.2f, %.2f]\n",
            min(judge_stats$raw_confirm_rate),
            max(judge_stats$raw_confirm_rate)))

# Keep judges with >= 5 cases (lower threshold for adequate sample)
judge_stats <- judge_stats[n_cases >= 5]
cases <- cases[paste(court_id, judge_clean) %in%
                 paste(judge_stats$court_id, judge_stats$judge_clean)]
cat(sprintf("After dropping judges with <5 cases: %d cases, %d judges\n",
            nrow(cases), nrow(judge_stats)))

# Leave-one-out leniency for each case
cases[, loo_leniency := {
  judge_total <- sum(confirmed_proxy)
  judge_n <- .N
  (judge_total - confirmed_proxy) / (judge_n - 1)
}, by = .(court_id, judge_clean)]

cat(sprintf("LOO leniency range: [%.3f, %.3f]\n",
            min(cases$loo_leniency), max(cases$loo_leniency)))

# -----------------------------------------------------------------------
# 4. Court-to-state mapping
# -----------------------------------------------------------------------

court_state <- data.table(
  court_id = c("flsb", "ilnb", "mieb", "txsb", "ganb",
               "tnmb", "mdb", "njb", "ohsb", "vaeb"),
  state_fips = c("12", "17", "26", "48", "13", "47", "24", "34", "39", "51"),
  state_name = c("Florida", "Illinois", "Michigan", "Texas", "Georgia",
                 "Tennessee", "Maryland", "New Jersey", "Ohio", "Virginia")
)

cases <- merge(cases, court_state, by = "court_id", all.x = TRUE)

# -----------------------------------------------------------------------
# 5. Aggregate to court-year panel
# -----------------------------------------------------------------------

court_year <- cases[, .(
  n_cases = .N,
  n_judges = uniqueN(judge_clean),
  confirm_rate = mean(confirmed_proxy),
  avg_leniency = mean(loo_leniency),
  sd_leniency = sd(loo_leniency),
  mean_duration = mean(duration_days),
  total_confirmed = sum(confirmed_proxy)
), by = .(court_id, state_fips, file_year)]

cat(sprintf("\nCourt-year panel: %d observations\n", nrow(court_year)))
cat(sprintf("  Courts: %d\n", uniqueN(court_year$court_id)))
cat(sprintf("  Years: %d-%d\n", min(court_year$file_year), max(court_year$file_year)))

# -----------------------------------------------------------------------
# 6. Load and merge Census BDS data (state-level, annual)
# -----------------------------------------------------------------------

bds <- fread(file.path(DATA_DIR, "census_bds_state_annual.csv"))
bds[, state_fips := as.character(state_fips)]
cat(sprintf("\nLoaded BDS: %d rows\n", nrow(bds)))

# Merge court-year with BDS at t=0 (concurrent year)
analysis <- merge(court_year, bds,
                  by.x = c("state_fips", "file_year"),
                  by.y = c("state_fips", "year"),
                  all.x = TRUE)

# Rename concurrent outcomes
setnames(analysis,
         c("estabs_entry", "estabs_entry_rate", "firms", "estabs",
           "estabs_exit", "estabs_exit_rate", "emp",
           "job_creation", "job_creation_rate"),
         c("entry_t0", "entry_rate_t0", "firms_t0", "estabs_t0",
           "exit_t0", "exit_rate_t0", "emp_t0",
           "job_creation_t0", "job_creation_rate_t0"))

# Merge t+1 outcomes
bds_t1 <- copy(bds)[, year := year - 1]
setnames(bds_t1,
         c("estabs_entry", "estabs_entry_rate", "firms", "emp"),
         c("entry_t1", "entry_rate_t1", "firms_t1", "emp_t1"))
analysis <- merge(analysis,
                  bds_t1[, .(state_fips, file_year = year,
                             entry_t1, entry_rate_t1, firms_t1, emp_t1)],
                  by = c("state_fips", "file_year"),
                  all.x = TRUE)

# Merge t+2 outcomes
bds_t2 <- copy(bds)[, year := year - 2]
setnames(bds_t2,
         c("estabs_entry", "estabs_entry_rate", "firms", "emp"),
         c("entry_t2", "entry_rate_t2", "firms_t2", "emp_t2"))
analysis <- merge(analysis,
                  bds_t2[, .(state_fips, file_year = year,
                             entry_t2, entry_rate_t2, firms_t2, emp_t2)],
                  by = c("state_fips", "file_year"),
                  all.x = TRUE)

# Merge t+3 outcomes
bds_t3 <- copy(bds)[, year := year - 3]
setnames(bds_t3,
         c("estabs_entry", "estabs_entry_rate"),
         c("entry_t3", "entry_rate_t3"))
analysis <- merge(analysis,
                  bds_t3[, .(state_fips, file_year = year,
                             entry_t3, entry_rate_t3)],
                  by = c("state_fips", "file_year"),
                  all.x = TRUE)

# Log outcomes
for (v in c("entry_t0", "entry_t1", "entry_t2", "entry_t3",
            "firms_t0", "firms_t1", "firms_t2",
            "emp_t0", "emp_t1", "emp_t2")) {
  if (v %in% names(analysis)) {
    analysis[, paste0("ln_", v) := log(get(v) + 1)]
  }
}

# -----------------------------------------------------------------------
# 7. Save analysis dataset
# -----------------------------------------------------------------------

fwrite(analysis, file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis_panel.csv: %d rows, %d columns\n",
            nrow(analysis), ncol(analysis)))

fwrite(cases, file.path(DATA_DIR, "cases_clean.csv"))
cat(sprintf("Saved cases_clean.csv: %d rows\n", nrow(cases)))

fwrite(judge_stats, file.path(DATA_DIR, "judge_stats.csv"))
cat(sprintf("Saved judge_stats.csv: %d rows\n", nrow(judge_stats)))

cat("\n=== Data cleaning complete ===\n")
