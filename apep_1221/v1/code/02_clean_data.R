## =============================================================================
## 02_clean_data.R — Construct analysis dataset
## Paper: Rejected and Relocated (apep_1221)
## =============================================================================

library(data.table)

dt <- fread("../data/inventor_app_panel.csv")
cat(sprintf("Loaded: %s rows\n", format(nrow(dt), big.mark = ",")))

## ---------------------------------------------------------------------------
## 1. Create inventor ID (name-based, standard in patent literature)
## ---------------------------------------------------------------------------

dt[, inventor_id := paste0(
  tolower(trimws(inventor_name_first)), "_",
  tolower(trimws(inventor_name_last))
)]

cat(sprintf("Unique inventors (name-based): %s\n",
            format(uniqueN(dt$inventor_id), big.mark = ",")))

## ---------------------------------------------------------------------------
## 2. Create rejection indicator
## ---------------------------------------------------------------------------

dt[, rejected := as.integer(disposal_type == "ABN")]

cat(sprintf("Rejection rate: %.1f%%\n", 100 * mean(dt$rejected)))

## ---------------------------------------------------------------------------
## 3. Construct art-unit x filing-year cells
## ---------------------------------------------------------------------------

# Truncate art unit to 3-digit technology center for broader grouping if needed
dt[, tech_center := substr(examiner_art_unit, 1, 3)]

# Art-unit x year cell identifier
dt[, au_year := paste0(examiner_art_unit, "_", filing_year)]

## ---------------------------------------------------------------------------
## 4. Count inventors per application (team size)
## ---------------------------------------------------------------------------

dt[, team_size := .N, by = application_number]

## ---------------------------------------------------------------------------
## 5. Compute leave-one-out examiner grant rate within AU x year
## ---------------------------------------------------------------------------

# First: examiner-level stats within AU x year
# Grant = 1 if ISS, = 0 if ABN
# For each application, we want the examiner's grant rate EXCLUDING that app

# Step 1: Get one row per application (for examiner stats)
app_dt <- unique(dt[, .(application_number, examiner_id, examiner_art_unit,
                         filing_year, au_year, rejected, disposal_type)])

# Examiner x AU x year: total grants and total decisions
examiner_au_yr <- app_dt[, .(
  total_grants = sum(disposal_type == "ISS"),
  total_apps   = .N
), by = .(examiner_id, au_year)]

# Merge back
app_dt <- merge(app_dt, examiner_au_yr,
                by = c("examiner_id", "au_year"), all.x = TRUE)

# Leave-one-out: subtract current application
app_dt[, loo_grants := total_grants - as.integer(disposal_type == "ISS")]
app_dt[, loo_apps := total_apps - 1L]

# LOO examiner grant rate (only if examiner has 2+ apps in cell)
app_dt[, examiner_leniency := fifelse(loo_apps >= 1, loo_grants / loo_apps, NA_real_)]

cat(sprintf("Applications with valid LOO leniency: %s / %s (%.1f%%)\n",
            format(sum(!is.na(app_dt$examiner_leniency)), big.mark = ","),
            format(nrow(app_dt), big.mark = ","),
            100 * mean(!is.na(app_dt$examiner_leniency))))

# Drop applications where examiner has only 1 app in AU-year (can't compute LOO)
app_dt <- app_dt[!is.na(examiner_leniency)]

## ---------------------------------------------------------------------------
## 6. Filter AU x year cells with enough examiners (minimum 3)
## ---------------------------------------------------------------------------

au_yr_examiners <- app_dt[, .(n_examiners = uniqueN(examiner_id)), by = au_year]
valid_cells <- au_yr_examiners[n_examiners >= 3]$au_year

app_dt <- app_dt[au_year %in% valid_cells]
cat(sprintf("After AU-year filter (≥3 examiners): %s applications\n",
            format(nrow(app_dt), big.mark = ",")))

## ---------------------------------------------------------------------------
## 7. Track inventor mobility across sequential applications
## ---------------------------------------------------------------------------

# Merge inventor info back to the application-level dataset
inv_dt <- merge(
  dt[, .(application_number, inventor_id, state, filing_date, team_size, small_entity_indicator, tech_center)],
  app_dt[, .(application_number, examiner_id, examiner_art_unit, filing_year,
             au_year, rejected, examiner_leniency, disposal_type)],
  by = "application_number", all = FALSE
)

# Sort by inventor and filing date
setorder(inv_dt, inventor_id, filing_date)

# Next application's state for the same inventor
inv_dt[, next_state := shift(state, type = "lead"), by = inventor_id]
inv_dt[, next_filing_year := shift(filing_year, type = "lead"), by = inventor_id]

# Moved indicator: state changed between this and next application
inv_dt[, moved := as.integer(!is.na(next_state) & state != next_state)]

# Only keep rows where we observe a subsequent application (can measure mobility)
analysis_dt <- inv_dt[!is.na(next_state)]

# Also require next filing within 10 years (avoid stale matches)
analysis_dt <- analysis_dt[next_filing_year - filing_year <= 10]

cat(sprintf("Analysis dataset: %s inventor-application pairs with mobility outcome\n",
            format(nrow(analysis_dt), big.mark = ",")))

## ---------------------------------------------------------------------------
## 8. Create additional controls
## ---------------------------------------------------------------------------

# Prior patents: count prior ISS for each inventor up to current filing date
setorder(analysis_dt, inventor_id, filing_date)
analysis_dt[, app_seq := seq_len(.N), by = inventor_id]
analysis_dt[, prior_grants := cumsum(disposal_type == "ISS") - as.integer(disposal_type == "ISS"),
            by = inventor_id]

# Solo inventor indicator
analysis_dt[, solo := as.integer(team_size == 1)]

# Small entity indicator
analysis_dt[, small_entity := as.integer(small_entity_indicator == "TRUE")]

## ---------------------------------------------------------------------------
## 9. Summary statistics
## ---------------------------------------------------------------------------

cat("\n=== ANALYSIS DATASET SUMMARY ===\n")
cat(sprintf("N inventor-app pairs: %s\n", format(nrow(analysis_dt), big.mark = ",")))
cat(sprintf("Unique inventors: %s\n", format(uniqueN(analysis_dt$inventor_id), big.mark = ",")))
cat(sprintf("Unique applications: %s\n", format(uniqueN(analysis_dt$application_number), big.mark = ",")))
cat(sprintf("Rejection rate: %.1f%%\n", 100 * mean(analysis_dt$rejected)))
cat(sprintf("Mobility rate (overall): %.2f%%\n", 100 * mean(analysis_dt$moved)))
cat(sprintf("Mobility rate (rejected): %.2f%%\n",
            100 * mean(analysis_dt$moved[analysis_dt$rejected == 1])))
cat(sprintf("Mobility rate (granted): %.2f%%\n",
            100 * mean(analysis_dt$moved[analysis_dt$rejected == 0])))
cat(sprintf("Mean examiner leniency: %.3f (SD=%.3f)\n",
            mean(analysis_dt$examiner_leniency), sd(analysis_dt$examiner_leniency)))
cat(sprintf("Filing years: %d-%d\n", min(analysis_dt$filing_year), max(analysis_dt$filing_year)))
cat(sprintf("Solo inventors: %.1f%%\n", 100 * mean(analysis_dt$solo)))

## ---------------------------------------------------------------------------
## 10. Save analysis dataset
## ---------------------------------------------------------------------------

# Keep only needed columns
keep_cols <- c("application_number", "inventor_id", "state", "next_state",
               "filing_year", "examiner_id", "examiner_art_unit", "au_year",
               "rejected", "moved", "examiner_leniency", "team_size",
               "solo", "prior_grants", "small_entity", "app_seq",
               "tech_center", "disposal_type")
analysis_dt <- analysis_dt[, ..keep_cols]

fwrite(analysis_dt, "../data/analysis_data.csv")
cat(sprintf("\nSaved analysis_data.csv: %.1f MB\n",
            file.size("../data/analysis_data.csv") / 1e6))

cat("Done.\n")
