# =============================================================================
# 02_clean_data.R — Build state × quarter panel for analysis
# =============================================================================
source("00_packages.R")

# ---------------------------------------------------------------------------
# A. Load raw data
# ---------------------------------------------------------------------------
trials <- fread(file.path(DATA_DIR, "clinical_trials_raw.csv"))
rtt_laws <- fread(file.path(DATA_DIR, "rtt_law_dates.csv"))

cat("Loaded", nrow(trials), "trial-state rows\n")
cat("Loaded", nrow(rtt_laws), "RTT law records\n")

# ---------------------------------------------------------------------------
# B. Parse dates and create quarter variables
# ---------------------------------------------------------------------------
# Start dates come in formats like "2014-03-15" or "2014-03"
trials[, start_date_parsed := as.Date(
  ifelse(nchar(start_date) == 7, paste0(start_date, "-01"), start_date)
)]
trials[, start_year := year(start_date_parsed)]
trials[, start_quarter := quarter(start_date_parsed)]
trials[, start_yq := start_year + (start_quarter - 1) / 4]

# Completion dates
trials[, completion_date_parsed := as.Date(
  ifelse(nchar(completion_date) == 7, paste0(completion_date, "-01"), completion_date),
  optional = TRUE
)]

# Duration in months (start to primary completion)
trials[, duration_months := as.numeric(
  difftime(completion_date_parsed, start_date_parsed, units = "days")
) / 30.44]

# ---------------------------------------------------------------------------
# C. Classify trials
# ---------------------------------------------------------------------------

# Phase classification
trials[, phase_cat := fcase(
  grepl("PHASE1", phases) & !grepl("PHASE2|PHASE3", phases), "Phase I",
  grepl("PHASE2", phases) & !grepl("PHASE3", phases), "Phase II",
  grepl("PHASE3", phases), "Phase III",
  grepl("PHASE4", phases), "Phase IV",
  grepl("EARLY_PHASE1", phases), "Early Phase I",
  default = "Other/NA"
)]

# Phase II/III indicator (main analysis sample)
trials[, is_phase23 := phase_cat %in% c("Phase II", "Phase III")]

# Study type
trials[, is_interventional := study_type == "INTERVENTIONAL"]
trials[, is_observational := study_type == "OBSERVATIONAL"]

# Sponsor type
trials[, is_industry := sponsor_class == "INDUSTRY"]

# Terminal condition classification
# Common terminal conditions in clinical trials
terminal_terms <- c(
  "cancer", "carcinoma", "lymphoma", "leukemia", "melanoma", "sarcoma",
  "glioblastoma", "pancreatic", "lung cancer", "brain tumor",
  "amyotrophic lateral sclerosis", "ALS", "duchenne",
  "metastatic", "advanced", "stage iv", "stage 4",
  "end-stage", "terminal", "fatal", "incurable",
  "hepatocellular", "mesothelioma", "cholangiocarcinoma"
)
terminal_pattern <- paste(terminal_terms, collapse = "|")
trials[, is_terminal := grepl(terminal_pattern, conditions, ignore.case = TRUE)]

# Non-terminal (placebo group)
nonterminal_terms <- c(
  "diabetes", "hypertension", "asthma", "arthritis", "depression",
  "anxiety", "obesity", "back pain", "knee", "hip", "dermatitis",
  "acne", "psoriasis", "eczema", "migraine", "insomnia",
  "allergy", "rhinitis", "osteoporosis"
)
nonterminal_pattern <- paste(nonterminal_terms, collapse = "|")
trials[, is_nonterminal := grepl(nonterminal_pattern, conditions, ignore.case = TRUE) &
         !is_terminal]

# Status classification
trials[, is_terminated := status %in% c("TERMINATED", "WITHDRAWN", "SUSPENDED")]
trials[, is_completed := status == "COMPLETED"]

cat("Phase distribution:\n")
print(trials[!is.na(facility_state), .N, by = phase_cat][order(-N)])
cat("\nTerminal condition share:", mean(trials$is_terminal, na.rm = TRUE), "\n")

# ---------------------------------------------------------------------------
# D. Build state × quarter panel
# ---------------------------------------------------------------------------

# State name standardization
us_states <- data.table(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC"),
  state_fips = c("01","02","04","05","06","08","09","10","12","13",
                 "15","16","17","18","19","20","21","22","23","24",
                 "25","26","27","28","29","30","31","32","33","34",
                 "35","36","37","38","39","40","41","42","44","45",
                 "46","47","48","49","50","51","53","54","55","56","11")
)

# Merge facility state names to FIPS
trials <- merge(trials, us_states, by.x = "facility_state", by.y = "state_name",
                all.x = TRUE)

# Drop non-US or unmatchable
trials_us <- trials[!is.na(state_fips)]
cat("After state matching:", nrow(trials_us), "rows\n")

# Create all state × quarter combinations
quarters <- CJ(
  state_fips = us_states$state_fips,
  year = 2008:2017,
  quarter = 1:4
)
quarters[, yq := year + (quarter - 1) / 4]
quarters[, time_id := (year - 2008) * 4 + quarter]  # Sequential quarter index

# Aggregate trial counts to state × quarter
# Main sample: Phase II/III interventional trials
main_agg <- trials_us[is_phase23 == TRUE & is_interventional == TRUE,
  .(
    n_trials        = uniqueN(nct_id),
    total_enrollment = sum(enrollment, na.rm = TRUE),
    mean_enrollment  = mean(enrollment, na.rm = TRUE),
    n_industry       = sum(is_industry, na.rm = TRUE),
    n_academic       = sum(!is_industry, na.rm = TRUE),
    n_terminal       = sum(is_terminal, na.rm = TRUE),
    n_nonterminal    = sum(is_nonterminal, na.rm = TRUE),
    n_terminated     = sum(is_terminated, na.rm = TRUE),
    n_completed      = sum(is_completed, na.rm = TRUE),
    median_duration  = median(duration_months, na.rm = TRUE)
  ),
  by = .(state_fips, start_year, start_quarter)
]

panel <- merge(quarters, main_agg,
               by.x = c("state_fips", "year", "quarter"),
               by.y = c("state_fips", "start_year", "start_quarter"),
               all.x = TRUE)

# Fill NAs with zeros for counts
count_cols <- c("n_trials", "total_enrollment", "n_industry", "n_academic",
                "n_terminal", "n_nonterminal", "n_terminated", "n_completed")
for (col in count_cols) {
  panel[is.na(get(col)), (col) := 0]
}

# ---------------------------------------------------------------------------
# E. Add placebo outcome panels
# ---------------------------------------------------------------------------

# Placebo 1: Phase I trials (not affected by Right-to-Try)
phase1_agg <- trials_us[phase_cat == "Phase I" & is_interventional == TRUE,
  .(n_phase1 = uniqueN(nct_id)),
  by = .(state_fips, start_year, start_quarter)
]
panel <- merge(panel, phase1_agg,
               by.x = c("state_fips", "year", "quarter"),
               by.y = c("state_fips", "start_year", "start_quarter"),
               all.x = TRUE)
panel[is.na(n_phase1), n_phase1 := 0]

# Placebo 2: Observational studies (not interventional drug trials)
obs_agg <- trials_us[is_observational == TRUE,
  .(n_observational = uniqueN(nct_id)),
  by = .(state_fips, start_year, start_quarter)
]
panel <- merge(panel, obs_agg,
               by.x = c("state_fips", "year", "quarter"),
               by.y = c("state_fips", "start_year", "start_quarter"),
               all.x = TRUE)
panel[is.na(n_observational), n_observational := 0]

# Placebo 3: Non-terminal condition trials (Phase II/III)
# Already in n_nonterminal column

# ---------------------------------------------------------------------------
# F. Merge treatment variable
# ---------------------------------------------------------------------------
rtt_laws[, rtt_date := as.Date(rtt_date)]
rtt_laws[, rtt_year := year(rtt_date)]
rtt_laws[, rtt_quarter := quarter(rtt_date)]
rtt_laws[, rtt_yq := rtt_year + (rtt_quarter - 1) / 4]
rtt_laws[, fips := sprintf("%02d", as.integer(fips))]

# Merge RTT law dates to panel
panel <- merge(panel, rtt_laws[, .(fips, rtt_yq)],
               by.x = "state_fips", by.y = "fips", all.x = TRUE)

# Treatment indicator: 1 if quarter >= adoption quarter
panel[, treated := fifelse(!is.na(rtt_yq) & yq >= rtt_yq, 1L, 0L)]

# Cohort variable for CS estimator (adoption quarter; 0 = never treated)
panel[, cohort_yq := fifelse(!is.na(rtt_yq), rtt_yq, 0)]

# State name for display
panel <- merge(panel, us_states[, .(state_fips, state_name)],
               by = "state_fips", all.x = TRUE)

# Log outcomes (adding 1 for zeros)
panel[, ln_trials := log(n_trials + 1)]
panel[, ln_enrollment := log(total_enrollment + 1)]
panel[, ln_terminal := log(n_terminal + 1)]
panel[, ln_nonterminal := log(n_nonterminal + 1)]
panel[, ln_phase1 := log(n_phase1 + 1)]
panel[, ln_observational := log(n_observational + 1)]

# Industry share
panel[, industry_share := fifelse(n_trials > 0, n_industry / n_trials, NA_real_)]
# Termination share
panel[, termination_share := fifelse(n_trials > 0, n_terminated / n_trials, NA_real_)]

cat("\n=== PANEL SUMMARY ===\n")
cat("Dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("States:", uniqueN(panel$state_fips), "\n")
cat("Quarters:", uniqueN(panel$time_id), "\n")
cat("Treated states:", uniqueN(panel$state_fips[panel$cohort_yq > 0]), "\n")
cat("Never-treated:", uniqueN(panel$state_fips[panel$cohort_yq == 0]), "\n")
cat("Mean trials/state/quarter:", round(mean(panel$n_trials), 1), "\n")
cat("Median trials/state/quarter:", median(panel$n_trials), "\n")

# Save
fwrite(panel, file.path(DATA_DIR, "panel_state_quarter.csv"))
cat("\nPanel saved to:", file.path(DATA_DIR, "panel_state_quarter.csv"), "\n")

# Summary statistics for the paper
summary_stats <- panel[, .(
  mean_trials       = mean(n_trials),
  sd_trials         = sd(n_trials),
  median_trials     = median(n_trials),
  mean_enrollment   = mean(total_enrollment),
  mean_terminal     = mean(n_terminal),
  mean_nonterminal  = mean(n_nonterminal),
  mean_phase1       = mean(n_phase1),
  mean_obs          = mean(n_observational),
  mean_industry_sh  = mean(industry_share, na.rm = TRUE)
)]
fwrite(summary_stats, file.path(DATA_DIR, "summary_stats.csv"))
cat("Summary stats saved\n")
