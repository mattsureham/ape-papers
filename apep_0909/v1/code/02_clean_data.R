# 02_clean_data.R — Clean and construct force × offence group × quarter panel
# PCC Electoral Cycles and Crime Investigation Quality (apep_0909)

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Read all quarterly XLSX files (2014/15 - 2023/24)
# ============================================================================
cat("=== Reading quarterly outcomes data ===\n")

xlsx_files <- list.files(data_dir, pattern = "^outcomes_20.*\\.xlsx$", full.names = TRUE)
cat(sprintf("Found %d XLSX files\n", length(xlsx_files)))

all_quarterly <- list()
for (f in sort(xlsx_files)) {
  cat(sprintf("  Reading %s...", basename(f)))
  tryCatch({
    # Find the data sheet (pattern: Outcomes_open_data_*)
    sheets <- readxl::excel_sheets(f)
    data_sheet <- grep("Outcomes_open_data", sheets, value = TRUE)
    if (length(data_sheet) == 0) {
      data_sheet <- grep("^(?!Cover|Notes|Pivot)", sheets, value = TRUE, perl = TRUE)
    }
    if (length(data_sheet) == 0) {
      cat(" no data sheet found\n")
      next
    }
    dt <- data.table(readxl::read_excel(f, sheet = data_sheet[1]))
    cat(sprintf(" %d rows, sheet: %s\n", nrow(dt), data_sheet[1]))
    all_quarterly[[basename(f)]] <- dt
  }, error = function(e) cat(sprintf(" ERROR: %s\n", e$message)))
}

# Also read the Apr-Sep 2024 file
apr_sep_file <- file.path(data_dir, "outcomes_apr_sep_2024.xlsx")
if (file.exists(apr_sep_file)) {
  cat("  Reading outcomes_apr_sep_2024.xlsx...")
  tryCatch({
    sheets <- readxl::excel_sheets(apr_sep_file)
    data_sheet <- grep("Outcomes_open_data|open_data", sheets, value = TRUE)
    if (length(data_sheet) > 0) {
      dt <- data.table(readxl::read_excel(apr_sep_file, sheet = data_sheet[1]))
      cat(sprintf(" %d rows\n", nrow(dt)))
      all_quarterly[["outcomes_apr_sep_2024.xlsx"]] <- dt
    } else {
      cat(sprintf(" sheets: %s\n", paste(sheets, collapse = ", ")))
    }
  }, error = function(e) cat(sprintf(" ERROR: %s\n", e$message)))
}

# ============================================================================
# 2. Standardize column names and combine
# ============================================================================
cat("\n=== Standardizing and combining quarterly data ===\n")

# Check column names across files
for (name in names(all_quarterly)) {
  cat(sprintf("  %s: %s\n", name, paste(names(all_quarterly[[name]]), collapse = " | ")))
}

# Standardize column names
standardize_cols <- function(dt) {
  cols <- names(dt)
  # Map to standard names
  new_names <- cols
  new_names <- gsub("Financial Year", "fin_year", new_names)
  new_names <- gsub("Financial Quarter", "fin_quarter", new_names)
  new_names <- gsub("Force Name", "force_name", new_names)
  new_names <- gsub("Offence Description", "offence_desc", new_names)
  new_names <- gsub("Offence Group", "offence_group", new_names)
  new_names <- gsub("Offence Subgroup", "offence_subgroup", new_names)
  new_names <- gsub("Offence Code", "offence_code", new_names)
  new_names <- gsub("Offence code expired", "offence_expired", new_names)
  new_names <- gsub("Outcome Description", "outcome_desc", new_names)
  new_names <- gsub("Outcome Group", "outcome_group", new_names)
  new_names <- gsub("Outcome Type", "outcome_type", new_names)
  new_names <- gsub("Outcomes for offences that were recorded in the quarter",
                    "outcomes_recorded", new_names)
  new_names <- gsub("Outcomes for investigations closed in the quarter",
                    "outcomes_closed", new_names)
  setnames(dt, cols, new_names)
  return(dt)
}

combined <- rbindlist(
  lapply(all_quarterly, function(dt) {
    dt <- standardize_cols(copy(dt))
    # Keep only needed columns
    keep_cols <- c("fin_year", "fin_quarter", "force_name", "offence_group",
                   "outcome_type", "outcome_desc", "outcomes_recorded")
    keep_cols <- intersect(keep_cols, names(dt))
    dt[, ..keep_cols]
  }),
  fill = TRUE
)

cat(sprintf("Combined quarterly data: %d rows\n", nrow(combined)))
cat(sprintf("Financial years: %s\n", paste(sort(unique(combined$fin_year)), collapse = ", ")))
cat(sprintf("Forces: %d unique\n", uniqueN(combined$force_name)))
cat(sprintf("Offence groups: %d unique\n", uniqueN(combined$offence_group)))

# ============================================================================
# 3. Convert outcomes_recorded to numeric
# ============================================================================
# Some files have ".." or "*" for suppressed values
combined[, outcomes_n := suppressWarnings(as.numeric(outcomes_recorded))]
cat(sprintf("Numeric conversion: %d non-missing out of %d total\n",
            sum(!is.na(combined$outcomes_n)), nrow(combined)))

# Drop rows with missing counts (suppressed cells)
combined <- combined[!is.na(outcomes_n)]
cat(sprintf("After dropping suppressed: %d rows\n", nrow(combined)))

# ============================================================================
# 4. Map financial year + quarter to calendar dates
# ============================================================================
# Financial year 2014/15, Q1 = Apr-Jun 2014
# Financial year 2014/15, Q2 = Jul-Sep 2014
# Financial year 2014/15, Q3 = Oct-Dec 2014
# Financial year 2014/15, Q4 = Jan-Mar 2015

combined[, start_year := as.integer(substr(fin_year, 1, 4))]
combined[, fin_quarter := as.integer(fin_quarter)]

# Calendar quarter mapping
combined[, cal_year := fifelse(fin_quarter <= 3, start_year, start_year + 1L)]
combined[, cal_quarter := fifelse(fin_quarter == 1, 2L,  # Apr-Jun = Q2
                          fifelse(fin_quarter == 2, 3L,  # Jul-Sep = Q3
                          fifelse(fin_quarter == 3, 4L,  # Oct-Dec = Q4
                                                   1L)))]  # Jan-Mar = Q1

# Create a numeric quarter index for time series
combined[, yq := cal_year + (cal_quarter - 1) / 4]

cat(sprintf("Calendar date range: %d Q%d to %d Q%d\n",
            min(combined$cal_year), combined[cal_year == min(cal_year), min(cal_quarter)],
            max(combined$cal_year), combined[cal_year == max(cal_year), max(cal_quarter)]))

# ============================================================================
# 5. Classify forces: PCC vs non-PCC
# ============================================================================
cat("\n=== Classifying forces ===\n")

# Print all force names
cat("All forces:\n")
print(sort(unique(combined$force_name)))

# Non-PCC forces (controls/placebos)
non_pcc <- c("Metropolitan Police", "City of London",
             "British Transport Police", "Action Fraud")
# BTP and Action Fraud are national, not territorial — exclude from analysis

combined[, pcc := fifelse(force_name %in% non_pcc, 0L, 1L)]
combined[, exclude := fifelse(force_name %in% c("British Transport Police",
                                                  "Action Fraud"), 1L, 0L)]

cat(sprintf("PCC forces: %d\n",
            uniqueN(combined[pcc == 1 & exclude == 0]$force_name)))
cat(sprintf("Non-PCC placebo forces: %d\n",
            uniqueN(combined[pcc == 0 & exclude == 0]$force_name)))
cat(sprintf("Excluded forces: %d\n",
            uniqueN(combined[exclude == 1]$force_name)))

# ============================================================================
# 6. Aggregate to force × offence group × quarter panel
# ============================================================================
cat("\n=== Aggregating to force × offence group × quarter ===\n")

# Create broad outcome categories for our analysis
# Key outcomes:
# Type 1: Charged/Summonsed
# Type 2: Caution (adult/juvenile)
# Type 3: Community resolution
# Type 4-8: Various formal disposals
# Type 14: Investigation complete; no suspect identified
# Type 15: Evidential difficulties (named suspect)
# Type 16: Evidential difficulties (unnamed)
# Type 17: Prosecution prevented/not in public interest
# Type 18: Investigation complete; suspect not identified (later codes)

# Print outcome types
cat("\nOutcome types in data:\n")
outcome_types <- combined[, .(n = sum(outcomes_n)),
                          by = .(outcome_type, outcome_desc)]
outcome_types <- outcome_types[order(outcome_type)]
print(outcome_types)

# Create broad categories
combined[, outcome_cat := fcase(
  outcome_type == 1, "charged",
  outcome_type %in% c(2, 3, 4, 5, 6, 7, 8), "other_formal",
  outcome_type == 14 | outcome_type == 18, "no_suspect",
  outcome_type %in% c(15, 16), "evidential_difficulties",
  outcome_type == 17, "not_public_interest",
  default = "other"
)]

# Aggregate: force × offence_group × quarter × outcome_cat
panel <- combined[exclude == 0,
  .(n_outcomes = sum(outcomes_n)),
  by = .(force_name, offence_group, cal_year, cal_quarter, yq, pcc, outcome_cat)
]

# Pivot wider: one row per force × offence_group × quarter
panel_wide <- dcast(panel,
  force_name + offence_group + cal_year + cal_quarter + yq + pcc ~ outcome_cat,
  value.var = "n_outcomes", fill = 0)

# Calculate total outcomes and rates
outcome_cols <- c("charged", "other_formal", "no_suspect",
                  "evidential_difficulties", "not_public_interest", "other")
outcome_cols <- intersect(outcome_cols, names(panel_wide))

panel_wide[, total_outcomes := rowSums(.SD, na.rm = TRUE), .SDcols = outcome_cols]

# Compute rates (share of total outcomes)
for (col in outcome_cols) {
  rate_col <- paste0(col, "_rate")
  panel_wide[, (rate_col) := fifelse(total_outcomes > 0,
                                      get(col) / total_outcomes, NA_real_)]
}

cat(sprintf("Panel: %d rows (force × offence group × quarter)\n", nrow(panel_wide)))
cat(sprintf("Forces: %d\n", uniqueN(panel_wide$force_name)))
cat(sprintf("Offence groups: %d\n", uniqueN(panel_wide$offence_group)))
cat(sprintf("Time periods: %d quarters\n", uniqueN(panel_wide$yq)))

# ============================================================================
# 7. Create election timing variables
# ============================================================================
cat("\n=== Creating election timing variables ===\n")

# PCC Elections (approximate calendar quarter):
# Election 1: November 2012 → 2012 Q4
# Election 2: May 2016 → 2016 Q2
# Election 3: May 2021 → 2021 Q2
# Election 4: May 2024 → 2024 Q2

elections <- data.table(
  election_num = 1:4,
  election_yq = c(2012 + 3/4, 2016 + 1/4, 2021 + 1/4, 2024 + 1/4),
  election_year = c(2012, 2016, 2021, 2024),
  election_quarter = c(4, 2, 2, 2)
)

# For the stacked event study, we assign each quarter to its nearest election
# and compute the event-time distance

# Create event-time for each election
# Each quarter gets assigned to nearest election within a window
# Window: 8 quarters before to 8 quarters after

panel_stacked <- list()

for (i in 1:nrow(elections)) {
  e <- elections[i]
  e_yq <- e$election_yq

  # Window: 8 quarters before to 8 quarters after
  window_start <- e_yq - 2.0  # 8 quarters before
  window_end <- e_yq + 2.0    # 8 quarters after

  dt_window <- panel_wide[yq >= window_start & yq <= window_end]
  dt_window[, election_num := e$election_num]
  dt_window[, event_time := round((yq - e_yq) * 4)]  # quarters relative to election

  panel_stacked[[i]] <- dt_window
}

stacked <- rbindlist(panel_stacked)

# Remove duplicate observations (quarters that fall in multiple election windows)
# Keep the assignment to the nearest election
stacked[, dist_to_election := abs(event_time)]
stacked <- stacked[stacked[, .I[which.min(dist_to_election)],
                           by = .(force_name, offence_group, cal_year, cal_quarter)]$V1]

cat(sprintf("Stacked panel: %d rows\n", nrow(stacked)))
cat(sprintf("Elections covered: %s\n",
            paste(unique(stacked$election_num), collapse = ", ")))
cat(sprintf("Event time range: %d to %d quarters\n",
            min(stacked$event_time), max(stacked$event_time)))

# ============================================================================
# 8. Also create a simple quarterly panel (not stacked) for robustness
# ============================================================================
# Aggregate across offence groups for force × quarter level
force_quarter <- panel_wide[,
  .(charged = sum(charged, na.rm = TRUE),
    no_suspect = sum(no_suspect, na.rm = TRUE),
    evidential_difficulties = sum(evidential_difficulties, na.rm = TRUE),
    total_outcomes = sum(total_outcomes, na.rm = TRUE)),
  by = .(force_name, cal_year, cal_quarter, yq, pcc)
]

force_quarter[, charged_rate := fifelse(total_outcomes > 0,
                                         charged / total_outcomes, NA_real_)]
force_quarter[, no_suspect_rate := fifelse(total_outcomes > 0,
                                           no_suspect / total_outcomes, NA_real_)]
force_quarter[, evid_diff_rate := fifelse(total_outcomes > 0,
                                          evidential_difficulties / total_outcomes,
                                          NA_real_)]

cat(sprintf("\nForce × quarter panel: %d rows\n", nrow(force_quarter)))

# ============================================================================
# 9. Save cleaned data
# ============================================================================
saveRDS(panel_wide, file.path(data_dir, "panel_wide.rds"))
saveRDS(stacked, file.path(data_dir, "stacked_panel.rds"))
saveRDS(force_quarter, file.path(data_dir, "force_quarter.rds"))

cat("\n=== Summary statistics ===\n")
cat(sprintf("Charge rate: mean=%.3f, sd=%.3f\n",
            mean(force_quarter$charged_rate, na.rm = TRUE),
            sd(force_quarter$charged_rate, na.rm = TRUE)))
cat(sprintf("No suspect rate: mean=%.3f, sd=%.3f\n",
            mean(force_quarter$no_suspect_rate, na.rm = TRUE),
            sd(force_quarter$no_suspect_rate, na.rm = TRUE)))
cat(sprintf("Total outcomes per force-quarter: mean=%.0f, sd=%.0f\n",
            mean(force_quarter$total_outcomes, na.rm = TRUE),
            sd(force_quarter$total_outcomes, na.rm = TRUE)))

cat("\n=== Data cleaning complete ===\n")
